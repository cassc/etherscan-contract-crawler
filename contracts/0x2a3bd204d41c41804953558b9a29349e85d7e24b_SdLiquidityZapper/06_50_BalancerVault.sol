//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/ILiquidityGaugeStrat.sol";
import "./BalancerStrategy.sol";
import "../interfaces/BalancerVault/IBalancerVault.sol";
import "../interfaces/IBalancerPool.sol";

contract BalancerVault is ERC20Upgradeable {
	using SafeERC20Upgradeable for ERC20Upgradeable;
	using AddressUpgradeable for address;

	ERC20Upgradeable public token;
	address public governance;
	uint256 public withdrawalFee;
	uint256 public keeperFee;
	address public liquidityGauge;
	uint256 public accumulatedFee;
	bytes32 public poolId;
	address public constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
	uint256 public min;
	uint256 public constant max = 10000;
	BalancerStrategy public balancerStrategy;

	event Earn(address _token, uint256 _amount);
	event Deposit(address _depositor, uint256 _amount);
	event Withdraw(address _depositor, uint256 _amount);

	function init(
		ERC20Upgradeable _token,
		address _governance,
		string memory name_,
		string memory symbol_,
		BalancerStrategy _balancerStrategy
	) public initializer {
		__ERC20_init(name_, symbol_);
		token = _token;
		governance = _governance;
		min = 10000;
		keeperFee = 10; // %0.1
		poolId = IBalancerPool(address(_token)).getPoolId();
		balancerStrategy = _balancerStrategy;
	}

	/// @notice function to deposit the BPT token
	/// @param _staker address to stake for
	/// @param _amount amount to deposit
	/// @param _earn earn or not
	function deposit(
		address _staker,
		uint256 _amount,
		bool _earn
	) public {
		require(address(liquidityGauge) != address(0), "Gauge not yet initialized");
		token.safeTransferFrom(msg.sender, address(this), _amount);
		_deposit(_staker, _amount, _earn);
	}

	/// @notice function to provide liquidity in underlying tokens
	/// @param _staker address to stake for
	/// @param _maxAmountsIn amounts for each underlying token
	/// @param _earn earn or not
	/// @param _minAmount amount to deposit
	function provideLiquidityAndDeposit(
		address _staker,
		uint256[] calldata _maxAmountsIn,
		bool _earn,
		uint256 _minAmount
	) public {
		require(address(liquidityGauge) != address(0), "Gauge not yet initialized");
		(IERC20[] memory tokens, , ) = IBalancerVault(BALANCER_VAULT).getPoolTokens(poolId);
		require(tokens.length == _maxAmountsIn.length, "!length");
		address[] memory assets = new address[](tokens.length);
		for (uint256 i; i < tokens.length; i++) {
			if (_maxAmountsIn[i] > 0) {
				tokens[i].transferFrom(msg.sender, address(this), _maxAmountsIn[i]);
				tokens[i].approve(BALANCER_VAULT, _maxAmountsIn[i]);
			}
			assets[i] = address(tokens[i]);
		}
		IBalancerVault.JoinPoolRequest memory pr = IBalancerVault.JoinPoolRequest(
			assets,
			_maxAmountsIn,
			abi.encode(1, _maxAmountsIn, _minAmount),
			false
		);
		uint256 lpBalanceBefore = token.balanceOf(address(this));
		IBalancerVault(BALANCER_VAULT).joinPool(
			poolId, // poolId
			address(this),
			address(this),
			pr
		);
		uint256 lpBalanceAfter = token.balanceOf(address(this));

		_deposit(_staker, lpBalanceAfter - lpBalanceBefore, _earn);
	}

	/// @notice internal deposit function
	/// @param _staker address to stake for
	/// @param _amount amount to deposit
	/// @param _earn earn or not
	function _deposit(
		address _staker,
		uint256 _amount,
		bool _earn
	) internal {
		if (!_earn) {
			uint256 keeperCut = (_amount * keeperFee) / 10000;
			_amount -= keeperCut;
			accumulatedFee += keeperCut;
		} else {
			_amount += accumulatedFee;
			accumulatedFee = 0;
		}
		_mint(address(this), _amount);
		ILiquidityGaugeStrat(liquidityGauge).deposit(_amount, _staker);
		if (_earn) {
			earn();
		}
		emit Deposit(_staker, _amount);
	}

	/// @notice function to withdraw
	/// @param _shares amount to withdraw
	function withdraw(uint256 _shares) public {
		uint256 userTotalShares = ILiquidityGaugeStrat(liquidityGauge).balanceOf(msg.sender);
		require(_shares <= userTotalShares, "Not enough staked");
		ILiquidityGaugeStrat(liquidityGauge).withdraw(_shares, msg.sender, true);
		_burn(address(this), _shares);
		uint256 tokenBalance = token.balanceOf(address(this)) - accumulatedFee;
		uint256 withdrawFee;
		if (_shares > tokenBalance) {
			uint256 amountToWithdraw = _shares - tokenBalance;
			balancerStrategy.withdraw(address(token), amountToWithdraw);
			withdrawFee = (amountToWithdraw * withdrawalFee) / 10000;
			if (withdrawFee > 0) {
				token.safeTransfer(governance, withdrawFee);
			}
		}
		token.safeTransfer(msg.sender, _shares - withdrawFee);
		emit Withdraw(msg.sender, _shares - withdrawFee);
	}

	/// @notice function to set the governance
	/// @param _governance governance address
	function setGovernance(address _governance) external {
		require(msg.sender == governance, "!governance");
		governance = _governance;
	}

	/// @notice function to set the keeper fee
	/// @param _newFee keeper fee
	function setKeeperFee(uint256 _newFee) external {
		require(msg.sender == governance, "!governance");
		keeperFee = _newFee;
	}

	/// @notice function to set the gauge multi rewards
	/// @param _liquidityGauge gauge address
	function setLiquidityGauge(address _liquidityGauge) external {
		require(msg.sender == governance, "!governance");
		liquidityGauge = _liquidityGauge;
		ERC20Upgradeable(address(this)).approve(liquidityGauge, type(uint256).max);
	}

	/// @notice function to set the balancer strategy
	/// @param _newStrat balancer strategy infos
	function setBalancerStrategy(BalancerStrategy _newStrat) external {
		require(msg.sender == governance, "!governance");
		balancerStrategy = _newStrat;
	}

	/// @notice function to return the vault token decimals
	function decimals() public view override returns (uint8) {
		return token.decimals();
	}

	/// @notice function to set the withdrawn fee
	/// @param _newFee withdrawn fee
	function setWithdrawnFee(uint256 _newFee) external {
		require(msg.sender == governance, "!governance");
		withdrawalFee = _newFee;
	}

	/// @notice function to set the min
	/// @param _min min amount
	function setMin(uint256 _min) external {
		require(msg.sender == governance, "!governance");
		min = _min;
	}

	/// @notice view function to fetch the available amount to send to the strategy
	function available() public view returns (uint256) {
		return ((token.balanceOf(address(this)) - accumulatedFee) * min) / max;
	}

	/// @notice internal function to move funds to the strategy
	function earn() internal {
		uint256 tokenBalance = available();
		token.approve(address(balancerStrategy), 0);
		token.approve(address(balancerStrategy), tokenBalance);
		balancerStrategy.deposit(address(token), tokenBalance);
		emit Earn(address(token), tokenBalance);
	}
}