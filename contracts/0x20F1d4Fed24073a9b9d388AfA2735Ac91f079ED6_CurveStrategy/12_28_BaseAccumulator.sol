// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ILocker.sol";
import "../interfaces/ILiquidityGauge.sol";
import { ISDTDistributor } from "../interfaces/ISDTDistributor.sol";

/// @title BaseAccumulator
/// @notice A contract that defines the functions shared by all accumulators
/// @author StakeDAO
contract BaseAccumulator {
	using SafeERC20 for IERC20;
	/* ========== STATE VARIABLES ========== */
	address public governance;
	address public locker;
	address public tokenReward;
	address public gauge;
	address public sdtDistributor;
	uint256 public claimerFee;

	/* ========== EVENTS ========== */

	event SdtDistributorUpdated(address oldDistributor, address newDistributor);
	event GaugeSet(address oldGauge, address newGauge);
	event RewardNotified(address gauge, address tokenReward, uint256 amount);
	event LockerSet(address oldLocker, address newLocker);
	event GovernanceSet(address oldGov, address newGov);
	event TokenRewardSet(address oldTr, address newTr);
	event TokenDeposited(address token, uint256 amount);
	event ERC20Rescued(address token, uint256 amount);

	/* ========== CONSTRUCTOR ========== */
	constructor(address _tokenReward) {
		tokenReward = _tokenReward;
		governance = msg.sender;
	}

	/* ========== MUTATIVE FUNCTIONS ========== */

	/// @notice Notify the reward using an extra token
	/// @param _tokenReward token address to notify
	/// @param _amount amount to notify
	function notifyExtraReward(address _tokenReward, uint256 _amount) external {
		require(msg.sender == governance, "!gov");
		_notifyReward(_tokenReward, _amount, true);
	}

	/// @notice Notify the reward using all balance of extra token
	/// @param _tokenReward token address to notify
	function notifyAllExtraReward(address _tokenReward) external {
		require(msg.sender == governance, "!gov");
		uint256 amount = IERC20(_tokenReward).balanceOf(address(this));
		_notifyReward(_tokenReward, amount, true);
	}

	/// @notice Notify the new reward to the LGV4
	/// @param _tokenReward token to notify
	/// @param _amount amount to notify
	function _notifyReward(
		address _tokenReward,
		uint256 _amount,
		bool _distributeSDT
	) internal {
		require(gauge != address(0), "gauge not set");
		require(_amount > 0, "set an amount > 0");
		uint256 balanceBefore = IERC20(_tokenReward).balanceOf(address(this));
		require(balanceBefore >= _amount, "amount not enough");
		if (ILiquidityGauge(gauge).reward_data(_tokenReward).distributor != address(0)) {
			if (_distributeSDT) {
				// Distribute SDT
				ISDTDistributor(sdtDistributor).distribute(gauge);
			}
			uint256 claimerReward = (_amount * claimerFee) / 10000;
			IERC20(_tokenReward).transfer(msg.sender, claimerReward);
			_amount -= claimerReward;
			IERC20(_tokenReward).approve(gauge, _amount);
			ILiquidityGauge(gauge).deposit_reward_token(_tokenReward, _amount);

			uint256 balanceAfter = IERC20(_tokenReward).balanceOf(address(this));

			require(balanceBefore - balanceAfter == _amount, "wrong amount notified");

			emit RewardNotified(gauge, _tokenReward, _amount);
		}
	}

	/// @notice Deposit token into the accumulator
	/// @param _token token to deposit
	/// @param _amount amount to deposit
	function depositToken(address _token, uint256 _amount) external {
		require(_amount > 0, "set an amount > 0");
		IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
		emit TokenDeposited(_token, _amount);
	}

	/// @notice Sets gauge for the accumulator which will receive and distribute the rewards
	/// @dev Can be called only by the governance
	/// @param _gauge gauge address
	function setGauge(address _gauge) external {
		require(msg.sender == governance, "!gov");
		require(_gauge != address(0), "can't be zero address");
		emit GaugeSet(gauge, _gauge);
		gauge = _gauge;
	}

	/// @notice Sets SdtDistributor to distribute from the Accumulator SDT Rewards to Gauge.
	/// @dev Can be called only by the governance
	/// @param _sdtDistributor gauge address
	function setSdtDistributor(address _sdtDistributor) external {
		require(msg.sender == governance, "!gov");
		require(_sdtDistributor != address(0), "can't be zero address");

		emit SdtDistributorUpdated(sdtDistributor, _sdtDistributor);
		sdtDistributor = _sdtDistributor;
	}

	/// @notice Allows the governance to set the new governance
	/// @dev Can be called only by the governance
	/// @param _governance governance address
	function setGovernance(address _governance) external {
		require(msg.sender == governance, "!gov");
		require(_governance != address(0), "can't be zero address");
		emit GovernanceSet(governance, _governance);
		governance = _governance;
	}

	/// @notice Allows the governance to set the locker
	/// @dev Can be called only by the governance
	/// @param _locker locker address
	function setLocker(address _locker) external {
		require(msg.sender == governance, "!gov");
		require(_locker != address(0), "can't be zero address");
		emit LockerSet(locker, _locker);
		locker = _locker;
	}

	/// @notice Allows the governance to set the token reward
	/// @dev Can be called only by the governance
	/// @param _tokenReward token reward address
	function setTokenReward(address _tokenReward) external {
		require(msg.sender == governance, "!gov");
		require(_tokenReward != address(0), "can't be zero address");
		emit TokenRewardSet(tokenReward, _tokenReward);
		tokenReward = _tokenReward;
	}

	function setClaimerFee(uint256 _claimerFee) external {
		require(msg.sender == governance, "!gov");
		claimerFee = _claimerFee;
	}

	/// @notice A function that rescue any ERC20 token
	/// @param _token token address
	/// @param _amount amount to rescue
	/// @param _recipient address to send token rescued
	function rescueERC20(
		address _token,
		uint256 _amount,
		address _recipient
	) external {
		require(msg.sender == governance, "!gov");
		require(_amount > 0, "set an amount > 0");
		require(_recipient != address(0), "can't be zero address");
		IERC20(_token).safeTransfer(_recipient, _amount);
		emit ERC20Rescued(_token, _amount);
	}
}