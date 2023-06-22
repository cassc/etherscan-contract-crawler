// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseAccumulator.sol";

/// @title A contract that accumulates sanUSDC_EUR rewards and notifies them to the LGV4
/// @author StakeDAO
contract AngleAccumulator is BaseAccumulator {
	/* ========== CONSTRUCTOR ========== */
	constructor(address _tokenReward) BaseAccumulator(_tokenReward) {}

	/* ========== MUTATIVE FUNCTIONS ========== */
	/// @notice Claims rewards from the locker and notify an amount to the LGV4
	/// @param _amount amount to notify after the claim
	function claimAndNotify(uint256 _amount) external {
		require(locker != address(0), "locker not set");
		ILocker(locker).claimRewards(tokenReward, address(this));
		_notifyReward(tokenReward, _amount);
	}

	/// @notice Claims rewards from the locker and notify all to the LGV4
	function claimAndNotifyAll() external {
		require(locker != address(0), "locker not set");
		ILocker(locker).claimRewards(tokenReward, address(this));
		uint256 amount = IERC20(tokenReward).balanceOf(address(this));
		_notifyReward(tokenReward, amount);
	}
}