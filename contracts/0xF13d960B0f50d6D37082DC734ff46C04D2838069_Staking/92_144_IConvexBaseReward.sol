// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface IConvexBaseRewards {
	//get balance of an address
	function balanceOf(address _account) external returns (uint256);

	//withdraw directly to curve LP token
	function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns (bool);

	//claim rewards
	function getReward() external returns (bool);
}