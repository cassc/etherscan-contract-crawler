// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import './IUniswapRouterETH.sol';
import './IUniswapV2Pair.sol';
import './IWrappedNative.sol';
import './StratManager.sol';
import './FeeManager.sol';
import './GasThrottler.sol';
import '../blocks/staking/pancakeswap/external/IMasterChefV2.sol';
import '../interfaces/external/ICurveSwap.sol';

contract StrategyCakeStableCurve2PoolLP is
	StratManager,
	FeeManager,
	GasThrottler
{
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	// Tokens used
	address public nativeStable;
	address public output;
	address public want;
	address public depositToken;

	// Third party contracts
	address public chef;
	uint256 public poolId;
	address public curveSwap;

	bool public harvestOnDeposit;
	uint256 public lastHarvest;

	// Routes
	address[] public outputToNativeStableRoute;
	address[] public outputToDepositRoute;

	event StratHarvest(
		address indexed harvester,
		uint256 wantHarvested,
		uint256 tvl
	);
	event Deposit(uint256 tvl);
	event Withdraw(uint256 tvl);
	event ChargedFees(uint256 callFees, uint256 bloomifyFees);

	constructor(
		address _want,
		uint256 _poolId,
		address _chef,
		address _vault,
		address _unirouter,
		address _keeper,
		address _bloomifyFeeRecipient,
		address _curveSwap,
		address[] memory _outputToNativeStableRoute,
		address[] memory _outputToDepositRoute
	) StratManager(_keeper, _unirouter, _vault, _bloomifyFeeRecipient) {
		want = _want;
		poolId = _poolId;
		chef = _chef;
		curveSwap = _curveSwap;

		outputToNativeStableRoute = _outputToNativeStableRoute;
		outputToDepositRoute = _outputToDepositRoute;
		output = _outputToNativeStableRoute[0];
		nativeStable = _outputToNativeStableRoute[
			_outputToNativeStableRoute.length - 1
		];

		// setup lp routing
		depositToken = _outputToDepositRoute[_outputToDepositRoute.length - 1];

		require(
			output == _outputToDepositRoute[0],
			"Output tokens don't match"
		);
		require(
			depositToken == ICurveSwap(curveSwap).coins(0) ||
				depositToken == ICurveSwap(curveSwap).coins(1),
			'Deposit token does not match curve swap'
		);

		_giveAllowances();
	}

	// puts the funds to work
	function deposit() public whenNotPaused {
		uint256 wantBal = IERC20(want).balanceOf(address(this));

		if (wantBal > 0) {
			IMasterChefV2(chef).deposit(poolId, wantBal);
			emit Deposit(balanceOf());
		}
	}

	function withdraw(uint256 _amount) external {
		require(msg.sender == vault, '!vault');

		uint256 wantBal = IERC20(want).balanceOf(address(this));

		if (wantBal < _amount) {
			IMasterChefV2(chef).withdraw(poolId, _amount.sub(wantBal));
			wantBal = IERC20(want).balanceOf(address(this));
		}

		if (wantBal > _amount) {
			wantBal = _amount;
		}

		if (tx.origin != owner() && !paused()) {
			uint256 withdrawalFeeAmount = wantBal.mul(withdrawalFee).div(
				WITHDRAWAL_MAX
			);
			wantBal = wantBal.sub(withdrawalFeeAmount);
		}

		IERC20(want).safeTransfer(vault, wantBal);

		emit Withdraw(balanceOf());
	}

	function beforeDeposit() external override {
		if (harvestOnDeposit) {
			require(msg.sender == vault, '!vault');
			_harvest(tx.origin);
		}
	}

	function harvest() external virtual gasThrottle {
		_harvest(tx.origin);
	}

	function harvest(address callFeeRecipient) external virtual gasThrottle {
		_harvest(callFeeRecipient);
	}

	function managerHarvest() external onlyManager {
		_harvest(tx.origin);
	}

	// compounds earnings and charges performance fee
	function _harvest(address callFeeRecipient) internal whenNotPaused {
		IMasterChefV2(chef).deposit(poolId, 0);
		uint256 outputBal = IERC20(output).balanceOf(address(this));
		if (outputBal > 0) {
			chargeFees(callFeeRecipient);
			addLiquidity();
			uint256 wantHarvested = balanceOfWant();
			deposit();

			lastHarvest = block.timestamp;
			emit StratHarvest(msg.sender, wantHarvested, balanceOf());
		}
	}

	// performance fees
	function chargeFees(address callFeeRecipient) internal {
		uint256 toNativeStable = IERC20(output)
			.balanceOf(address(this))
			.mul(425)
			.div(10000);

		IUniswapRouterETH router = IUniswapRouterETH(unirouter);
		uint256 amountOut = router.getAmountsOut(
			toNativeStable,
			outputToNativeStableRoute
		)[outputToNativeStableRoute.length - 1];
		router.swapExactTokensForTokens(
			toNativeStable,
			amountOut,
			outputToNativeStableRoute,
			address(this),
			block.timestamp
		);

		uint256 nativeStableBal = IERC20(nativeStable).balanceOf(address(this));

		uint256 callFeeAmount = nativeStableBal.mul(callFee).div(MAX_FEE);
		IERC20(nativeStable).safeTransfer(callFeeRecipient, callFeeAmount);

		uint256 bloomifyFeeAmount = nativeStableBal.mul(bloomifyFee).div(
			MAX_FEE
		);
		IERC20(nativeStable).safeTransfer(
			bloomifyFeeRecipient,
			bloomifyFeeAmount
		);

		emit ChargedFees(callFeeAmount, bloomifyFeeAmount);
	}

	// Adds liquidity to AMM and gets more LP tokens.
	function addLiquidity() internal {
		uint256 outputBal = IERC20(output).balanceOf(address(this));

		IUniswapRouterETH router = IUniswapRouterETH(unirouter);

		if (depositToken != output) {
			router.swapExactTokensForTokens(
				outputBal,
				0,
				outputToDepositRoute,
				address(this),
				block.timestamp
			);
		}

		uint256 depositBal = IERC20(depositToken).balanceOf(address(this));
		uint256[2] memory depositAmounts;
		if (depositToken == ICurveSwap(curveSwap).coins(0)) {
			depositAmounts[0] = depositBal;
			ICurveSwap(curveSwap).add_liquidity(depositAmounts, 0);
		} else {
			depositAmounts[1] = depositBal;
			ICurveSwap(curveSwap).add_liquidity(depositAmounts, 0);
		}
	}

	// calculate the total underlaying 'want' held by the strat.
	function balanceOf() public view returns (uint256) {
		return balanceOfWant().add(balanceOfPool());
	}

	// it calculates how much 'want' this contract holds.
	function balanceOfWant() public view returns (uint256) {
		return IERC20(want).balanceOf(address(this));
	}

	// it calculates how much 'want' the strategy has working in the farm.
	function balanceOfPool() public view returns (uint256) {
		(uint256 _amount, ) = IMasterChefV2(chef).userInfo(
			poolId,
			address(this)
		);
		return _amount;
	}

	// returns rewards unharvested
	function rewardsAvailable() public view returns (uint256) {
		return IMasterChefV2(chef).pendingCake(poolId, address(this));
	}

	// native reward amount for calling harvest
	function callReward() public view returns (uint256) {
		uint256 _outputBal = rewardsAvailable();
		uint256 _nativeBal;

		if (_outputBal > 0) {
			uint256[] memory _amountOut = IUniswapRouterETH(unirouter)
				.getAmountsOut(_outputBal, outputToNativeStableRoute);
			_nativeBal = _amountOut[_amountOut.length - 1];
		}

		return _nativeBal.mul(425).div(10000).mul(callFee).div(MAX_FEE);
	}

	function setHarvestOnDeposit(bool _harvestOnDeposit) external onlyManager {
		harvestOnDeposit = _harvestOnDeposit;

		if (harvestOnDeposit) {
			setWithdrawalFee(0);
		} else {
			setWithdrawalFee(10);
		}
	}

	function setShouldGasThrottle(bool _shouldGasThrottle)
		external
		onlyManager
	{
		shouldGasThrottle = _shouldGasThrottle;
	}

	// called as part of strat migration. Sends all the available funds back to the vault.
	function retireStrat() external {
		require(msg.sender == vault, '!vault');

		IMasterChefV2(chef).emergencyWithdraw(poolId);

		uint256 wantBal = IERC20(want).balanceOf(address(this));
		IERC20(want).transfer(vault, wantBal);
	}

	// pauses deposits and withdraws all funds from third party systems.
	function panic() public onlyManager {
		pause();
		IMasterChefV2(chef).emergencyWithdraw(poolId);
	}

	function pause() public onlyManager {
		_pause();

		_removeAllowances();
	}

	function unpause() external onlyManager {
		_unpause();

		_giveAllowances();

		deposit();
	}

	function _giveAllowances() internal {
		IERC20(want).safeApprove(chef, 0);
		IERC20(want).safeApprove(chef, type(uint256).max);

		IERC20(output).safeApprove(unirouter, 0);
		IERC20(output).safeApprove(unirouter, type(uint256).max);

		IERC20(nativeStable).safeApprove(unirouter, 0);
		IERC20(nativeStable).safeApprove(unirouter, type(uint256).max);

		IERC20(depositToken).safeApprove(curveSwap, 0);
		IERC20(depositToken).safeApprove(curveSwap, type(uint256).max);
	}

	function _removeAllowances() internal {
		IERC20(want).safeApprove(chef, 0);
		IERC20(output).safeApprove(unirouter, 0);
		IERC20(nativeStable).safeApprove(unirouter, 0);
		IERC20(depositToken).safeApprove(curveSwap, 0);
	}

	function outputToNative() external view returns (address[] memory) {
		return outputToNativeStableRoute;
	}

	function outputToDeposit() external view returns (address[] memory) {
		return outputToDepositRoute;
	}
}