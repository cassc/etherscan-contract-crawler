// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IMultiRewards {
	function balanceOf(address) external returns (uint256);

	function stakeFor(address, uint256) external;

	function withdrawFor(address, uint256) external;

	function notifyRewardAmount(address, uint256) external;

	function mintFor(address recipient, uint256 amount) external;

	function burnFrom(address _from, uint256 _amount) external;

	function stakeOf(address account) external view returns (uint256);
}