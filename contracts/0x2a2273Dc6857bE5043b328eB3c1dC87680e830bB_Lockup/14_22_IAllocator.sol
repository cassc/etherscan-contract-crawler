// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IAllocator {
	function beforeBalanceChange(
		address _property,
		address _from,
		address _to
	) external;

	function calculateMaxRewardsPerBlock() external view returns (uint256);
}