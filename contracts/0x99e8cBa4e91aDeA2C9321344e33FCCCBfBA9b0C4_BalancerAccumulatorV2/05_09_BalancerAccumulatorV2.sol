// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseAccumulator.sol";

/// @title A contract that accumulates rewards and notifies them to the LGV4
/// @author StakeDAO
contract BalancerAccumulatorV2 is BaseAccumulator {
	address[] public tokenData;

	/* ========== CONSTRUCTOR ========== */
	constructor(address _tokenReward, address _gauge) BaseAccumulator(_tokenReward, _gauge) {}

	/* ========== MUTATIVE FUNCTIONS ========== */
	/// @notice Claims rewards from the locker and notifies it to the LGV4
	/// @param _amount amount to notify
	function claimAndNotify(uint256 _amount) external {
		require(locker != address(0), "locker not set");
		ILocker(locker).claimRewards(tokenReward, address(this));
		_notifyReward(tokenReward, _amount);
		_distributeSDT();
	}

	/// @notice Claims rewards from the locker and notify all to the LGV4
	function claimAndNotifyAll() external {
		require(locker != address(0), "locker not set");
		ILocker(locker).claimRewards(tokenReward, address(this));
		uint256 amount = IERC20(tokenReward).balanceOf(address(this));
		_notifyReward(tokenReward, amount);
		_distributeSDT();
	}

	/// @notice Claims rewards from the locker and notify all to the LGV4
	function claimAllRewardsAndNotify() external {
		require(locker != address(0), "locker not set");
		ILocker(locker).claimAllRewards(tokenData, address(this));
		_notifyAllExtraReward(tokenData);
		_distributeSDT();
	}

	function addReward(address token) external {
		require(msg.sender == governance, "!gov");
		tokenData.push(token);
	}

	function setTokenRewards(address[] calldata tokens) external {
		require(msg.sender == governance, "!gov");
		tokenData = tokens;
	}
}