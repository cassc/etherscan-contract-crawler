// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRewardPool {
	function claim(address user, bool relock) external returns (uint256);

	function checkpoint_token() external;
}