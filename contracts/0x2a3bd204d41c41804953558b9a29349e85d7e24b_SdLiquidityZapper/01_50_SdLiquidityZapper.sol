pragma solidity ^0.8.7;

import { Depositor } from "../locking/Depositor.sol";
import { ICurvePool } from "../interfaces/ICurvePool.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { CurveVault } from "../strategy/CurveVault.sol";
import { BalancerVault } from "../strategy/BalancerVault.sol";
import { IBalancerVault } from "./BalancerZapper.sol";

contract SdLiquidityZapper {
	mapping(address => address) public depositors;
	address public governance;
	address public constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
	address public constant BPT = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
	address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
	address public constant SDBAL = 0xF24d8651578a55b0C119B9910759a351A3458895;
	address public constant BALANCER_DEPOSITOR = 0x3e0d44542972859de3CAdaF856B1a4FD351B4D2E;
	address public constant SDBALLP = 0x2d011aDf89f0576C9B722c28269FcB5D50C2d179;
	address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	bytes32 public constant SDBALPOOLID = 0x2d011adf89f0576c9b722c28269fcb5d50c2d17900020000000000000000024d;
	bytes32 public constant BPTPOOLID = 0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014;

	constructor() {
		governance = msg.sender;
		IERC20(BAL).approve(BALANCER_VAULT, type(uint256).max);
		IERC20(SDBAL).approve(BALANCER_VAULT, type(uint256).max);
		IERC20(BPT).approve(BALANCER_VAULT, type(uint256).max);
		IERC20(BPT).approve(BALANCER_DEPOSITOR, type(uint256).max);
	}

	///////////////////////////////////////////////
	////// EXTERNAL FUNCTIONS
	///////////////////////////////////////////////

	/**
	 ** @notice Lock the underlying tokens via depositor to locker 
	 then provide liquidity and jump into related Curve strategy
	 ** @param _token underlying token such as CRV,ANGLE,FXS
	 ** @param _totalAmount total underlying token amount
	 ** @param _amountToLock amount that will get 1:1 SD token by depositing to locker
	 ** @param _minAmount min LP token amount that we expect when we provide liquidity to Curve Pool
	 ** @param _pool Address of the token/SdToken Curve Pool
	 ** @param _strategyVault Address of the related Curve Strategy's vault
	 ** @param _earn Indicates if funds should be pushed underlying strategy from vault or will stay in vault 
	 */
	function zapToSdCurvePool(
		address _token,
		uint256 _totalAmount,
		uint256 _amountToLock,
		uint256 _minAmount,
		address _pool,
		address _strategyVault,
		bool _earn,
		bool _lock
	) external {
		IERC20(_token).transferFrom(msg.sender, address(this), _totalAmount);
		uint256 receivedSdToken;
		if (_amountToLock > 0) receivedSdToken = _lockTokens(_token, _amountToLock, _lock);

		uint256[2] memory _amounts = [_totalAmount - _amountToLock, receivedSdToken];

		_provideLiquidityCurve(_pool, _amounts, _minAmount);
		uint256 receivedLP = IERC20(_pool).balanceOf(address(this));
		CurveVault(_strategyVault).deposit(msg.sender, receivedLP, _earn);
	}

	/**
	** @notice Provide liquidity with BAL then lock some part of this LP tokens via depositor 
	after that provide liquidity to sdBAL balancer pool and jump into related balancer strategy
	** @param _amount Total BAL amount that user will deposit
	** @param _lockAmountPercentage Percentage for the BPT indicates that how many obtained BPT will be deposit to locker.The value in 10000
	** @param _minAmount Minimum LP token amount that we will get when we provide liquidity 
	** @param _minAmountSdLpReceived Minimum LP token amount that we will get when we provide Liquidity sdBAL Liquidity pool
	** @param _strategyVault Address of the related Balancer strategy's vault
	** @param _earn Indicates if funds should be pushed underlying strategy from vault or will stay in vault
	 */
	function zapToSdBalPool(
		uint256 _amount,
		uint256 _lockAmountPercentage,
		uint256 _minAmount,
		uint256 _minAmountSdLpReceived,
		address _strategyVault,
		bool _earn,
		bool _lock
	) external {
		// transfer BAL here
		IERC20(BAL).transferFrom(msg.sender, address(this), _amount);

		address[] memory assets = new address[](2);
		assets[0] = BAL;
		assets[1] = WETH;

		uint256[] memory maxAmountsIn = new uint256[](2);
		maxAmountsIn[0] = _amount;
		maxAmountsIn[1] = 0; // 0 WETH

		_provideLiquidityBalancer(BPTPOOLID, assets, maxAmountsIn, _minAmount);
		uint256 bptReceived = IERC20(BPT).balanceOf(address(this));
		uint256 lockAmount;
		uint256 receivedSdToken;
		if (_lockAmountPercentage > 0) {
			lockAmount = (bptReceived * _lockAmountPercentage) / 10000;
			receivedSdToken = _lockTokens(BAL, lockAmount, _lock);
		}

		assets[0] = BPT;
		assets[1] = SDBAL;
		maxAmountsIn[0] = bptReceived - lockAmount;
		maxAmountsIn[1] = receivedSdToken;
		_provideLiquidityBalancer(SDBALPOOLID, assets, maxAmountsIn, _minAmountSdLpReceived);
		uint256 lpBalanceAfter = IERC20(SDBALLP).balanceOf(address(this));
		uint256 allowance = IERC20(SDBALLP).allowance(address(this), _strategyVault);
		if (lpBalanceAfter > allowance) {
			IERC20(SDBALLP).approve(_strategyVault, 0);
			IERC20(SDBALLP).approve(_strategyVault, type(uint256).max);
		}
		BalancerVault(_strategyVault).deposit(msg.sender, lpBalanceAfter, _earn);
	}

	///////////////////////////////////////////////
	////// INTERNAL FUNCTIONS
	///////////////////////////////////////////////

	/**
	 ** @notice Provide liquidity to Curve pool
	 ** @param _amounts array of input amounts in size of 2
	 ** @param _minAmount minimum expected LP token amount
	 */
	function _provideLiquidityCurve(
		address _pool,
		uint256[2] memory _amounts,
		uint256 _minAmount
	) internal {
		ICurvePool(_pool).add_liquidity(_amounts, _minAmount);
	}

	/**
	 ** @notice Send the tokens via depositor to the locker then locking to underlying protocol and mints 1:1 SdTokens
	 ** @param _token address of the underlying token that we are planning to lock such as CRV,ANGLE,FXS
	 ** @param _amount amount of the tokens we are planning to lock
	 ** @param _lock indicates that if tokens should be locked to underlying protocol or needs to stay in depositor for gas saving
	 */
	function _lockTokens(
		address _token,
		uint256 _amount,
		bool _lock
	) internal returns (uint256 sdReceived) {
		address depositor = depositors[_token];
		Depositor(depositor).deposit(_amount, _lock, false, address(this));
		if (!_lock) {
			address sdToken = _token == BAL ? SDBAL : Depositor(depositor).minter();
			sdReceived = IERC20(sdToken).balanceOf(address(this));
		} else {
			sdReceived = _amount;
		}
	}

	/**
	 ** @notice Provide liquidity to Balancer Pool
	 ** @param _poolId id of the pool that we will provide liquidity
	 ** @param _assets addresses of the assets that we will provide liquidity
	 ** @param _maxAmountsIn amounts of the assets that we will provide liquidity
	 ** @param _minAmount minimum expected LP amount that we will get when we provide Liquidity
	 */
	function _provideLiquidityBalancer(
		bytes32 _poolId,
		address[] memory _assets,
		uint256[] memory _maxAmountsIn,
		uint256 _minAmount
	) internal {
		IBalancerVault.JoinPoolRequest memory pr = IBalancerVault.JoinPoolRequest(
			_assets,
			_maxAmountsIn,
			abi.encode(1, _maxAmountsIn, _minAmount),
			false
		);

		IBalancerVault(BALANCER_VAULT).joinPool(_poolId, address(this), address(this), pr);
	}

	///////////////////////////////////////////////
	////// SETTERS
	///////////////////////////////////////////////
	/**
	 ** @notice Adds related depositor to depositors and it maps it with underlying token such as CRV,ANGLE,FXS
	 ** @param _token address of the underlying token such as CRV,ANGLE,FXS
	 ** @param _depositor address of the depositor
	 ** @param _curvePool address of the token/SDToken Curve pool
	 ** @param _strategyVault address of the related Curve Strategy's vault
	 */

	function addDepositorForCurveBased(
		address _token,
		address _sdToken,
		address _depositor,
		address _curvePool,
		address _strategyVault
	) external {
		require(msg.sender == governance, "!governance");
		depositors[_token] = _depositor;
		IERC20(_curvePool).approve(_strategyVault, type(uint256).max);
		IERC20(_token).approve(_depositor, type(uint256).max);
		IERC20(_token).approve(_curvePool, type(uint256).max);
		IERC20(_sdToken).approve(_curvePool, type(uint256).max);
	}

	/**
	 ** @notice Change the depositor address for the underlying token
	 ** @param _token address of the underlying token
	 ** @param _newDepositor address of the new depositor
	 */
	function changeDepositor(address _token, address _newDepositor) external {
		require(msg.sender == governance, "!governance");
		depositors[_token] = _newDepositor;
		IERC20(_token).approve(_newDepositor, type(uint256).max);
	}

	/**
	 ** @notice Transfer the governance to another address
	 ** @param _newGovernance address of the new governance
	 */
	function transferGovernance(address _newGovernance) external {
		require(msg.sender == governance, "!governance");
		governance = _newGovernance;
	}
}