// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;

interface ILpDepositor {
	function balanceOf(address account) external view returns (uint256);

	function earned(address account) external view returns (uint256);

	function deposit(uint256 amount) external;

	function withdrawAll() external;

	function withdraw(uint256 amount) external;

	function getReward() external;

	function TOKEN() external view returns (address);

	function rewardToken() external view returns (address);
}