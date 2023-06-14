//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/ILiquidityGaugeStrat.sol";
import "./CurveStrategy.sol";

contract CurveVault is ERC20Upgradeable {
	using SafeERC20Upgradeable for ERC20Upgradeable;
	using AddressUpgradeable for address;

	ERC20Upgradeable public token;
	address public governance;
	uint256 public withdrawalFee;
	uint256 public keeperFee;
	address public liquidityGauge;
	uint256 public accumulatedFee;
	CurveStrategy public curveStrategy;
	uint256 public min;
	uint256 public constant MAX = 10000;

	event Earn(address _token, uint256 _amount);
	event Deposit(address _depositor, uint256 _amount);
	event Withdraw(address _depositor, uint256 _amount);

	function init(
		ERC20Upgradeable _token,
		address _governance,
		string memory name_,
		string memory symbol_,
		CurveStrategy _curveStrategy
	) public initializer {
		__ERC20_init(name_, symbol_);
		token = _token;
		governance = _governance;
		min = 10000;
		keeperFee = 10; // %0.1
		curveStrategy = _curveStrategy;
	}

	/// @notice function to deposit a new amount
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
		if (!_earn) {
			uint256 keeperCut = (_amount * keeperFee) / 10000;
			_amount -= keeperCut;
			accumulatedFee += keeperCut;
		} else {
			_amount += accumulatedFee;
			accumulatedFee = 0;
		}
		_mint(address(this), _amount);
		ERC20Upgradeable(address(this)).approve(liquidityGauge, _amount);
		ILiquidityGaugeStrat(liquidityGauge).deposit(_amount, _staker);
		if (_earn) {
			earn();
		}
		emit Deposit(msg.sender, _amount);
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
			curveStrategy.withdraw(address(token), amountToWithdraw);
			withdrawFee = (amountToWithdraw * withdrawalFee) / 10000;
			token.safeTransfer(governance, withdrawFee);
		}
		token.safeTransfer(msg.sender, _shares - withdrawFee);
		emit Withdraw(msg.sender, _shares - withdrawFee);
	}

	/// @notice function to withdraw all curve LPs deposited
	function withdrawAll() external {
		withdraw(balanceOf(msg.sender));
	}

	/// @notice function to set the governance
	/// @param _governance governance address
	function setGovernance(address _governance) external {
		require(msg.sender == governance, "!governance");
		require(_governance != address(0), "zero address");
		governance = _governance;
	}

	/// @notice function to set the keeper fee
	/// @param _newFee keeper fee
	function setKeeperFee(uint256 _newFee) external {
		require(msg.sender == governance, "!governance");
		require(_newFee <= MAX, "more than 100%");
		keeperFee = _newFee;
	}

	/// @notice function to set the gauge multi rewards
	/// @param _liquidityGauge gauge address
	function setLiquidityGauge(address _liquidityGauge) external {
		require(msg.sender == governance, "!governance");
		require(_liquidityGauge != address(0), "zero address");
		liquidityGauge = _liquidityGauge;
	}

	/// @notice function to set the curve strategy
	/// @param _newStrat curve strategy infos
	function setCurveStrategy(CurveStrategy _newStrat) external {
		require(msg.sender == governance, "!governance");
		require(address(_newStrat) != address(0), "zero address");
		// migration (send all LPs here)
		curveStrategy.migrateLP(address(token));
		curveStrategy = _newStrat;
		// deposit LPs into the new strategy
		earn();
	}

	/// @notice function to return the vault token decimals
	function decimals() public view override returns (uint8) {
		return token.decimals();
	}

	/// @notice function to set the withdrawn fee
	/// @param _newFee withdrawn fee
	function setWithdrawnFee(uint256 _newFee) external {
		require(msg.sender == governance, "!governance");
		require(_newFee <= MAX, "more than 100%");
		withdrawalFee = _newFee;
	}

	/// @notice function to set the min (it needs to be lower than MAX)
	/// @param _min min amount
	function setMin(uint256 _min) external {
		require(msg.sender == governance, "!governance");
		require(_min <= MAX, "more than 100%");
		min = _min;
	}

	/// @notice view function to fetch the available amount to send to the strategy
	function available() public view returns (uint256) {
		return ((token.balanceOf(address(this)) - accumulatedFee) * min) / MAX;
	}

	/// @notice internal function to move funds to the strategy
	function earn() internal {
		uint256 tokenBalance = available();
		token.approve(address(curveStrategy), 0);
		token.approve(address(curveStrategy), tokenBalance);
		curveStrategy.deposit(address(token), tokenBalance);
		emit Earn(address(token), tokenBalance);
	}
}