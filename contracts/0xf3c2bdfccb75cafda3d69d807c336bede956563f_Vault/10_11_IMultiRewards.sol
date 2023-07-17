// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IMultiRewards {
	function balanceOf(address) external returns(uint);
	function stakeFor(address, uint) external;
	function withdrawFor(address, uint) external;
	function notifyRewardAmount(address, uint) external;
}