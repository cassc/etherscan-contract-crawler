// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseAccumulator.sol";

/// @title A contract that accumulates APW rewards and notifies them to the LGV4
/// @author StakeDAO
contract ApwineAccumulator is BaseAccumulator {
	uint256 public lockerFee; // in 10000

	address public feeReceiver;

	/* ========== CONSTRUCTOR ========== */
	constructor(address _tokenReward, address _gauge) BaseAccumulator(_tokenReward, _gauge) {}

	/* ========== MUTATIVE FUNCTIONS ========== */
	/// @notice Claims rewards from the locker and notify an amount to the LGV4
	/// @param _amount amount to notify after the claim
	function claimAndNotify(uint256 _amount) external {
		require(locker != address(0), "locker not set");
		ILocker(locker).claimRewards(tokenReward, address(this));
		uint256 fee = (_amount * lockerFee) / 10000;
		if (fee > 0) IERC20(tokenReward).transfer(feeReceiver, fee);
		_notifyReward(tokenReward, _amount - fee);
		_distributeSDT();
	}

	/// @notice Claims rewards from the locker and notify all to the LGV4
	function claimAndNotifyAll() external {
		require(locker != address(0), "locker not set");
		ILocker(locker).claimRewards(tokenReward, address(this));
		uint256 amount = IERC20(tokenReward).balanceOf(address(this));
		uint256 fee = (amount * lockerFee) / 10000;
		if (fee > 0) IERC20(tokenReward).transfer(feeReceiver, fee);
		_notifyReward(tokenReward, amount - fee);
		_distributeSDT();
	}

	/// @notice Set new Fee receiver
	function setFeeReceiver(address _feeReceiver) external {
		require(msg.sender == governance, "!gov");
		require(_feeReceiver != address(0), "!address zero");
		feeReceiver = _feeReceiver;
	}

	/// @notice Set fee percentage
	function setLockerFee(uint256 _lockerFee) external {
		require(msg.sender == governance, "!gov");
		require(lockerFee <= 10000, "!>10000");
		lockerFee = _lockerFee;
	}
}