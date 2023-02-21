// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

//main Convex contract(booster.sol) basic interface
interface IConvexBooster {
	//deposit into convex, receive a tokenized deposit.  parameter to stake immediately
	function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns (bool);

	//get poolInfo for a poolId
	function poolInfo(
		uint256 _pid
	)
		external
		returns (address lptoken, address token, address gauge, address crvRewards, address stash, bool shutdown);
}