// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ILocker {
	function createLock(uint256, uint256) external;

	function claimAllRewards(address[] calldata _tokens, address _recipient) external;

	function increaseAmount(uint256) external;

	function increaseUnlockTime(uint256) external;

	function release() external;

	function claimRewards(address,address) external;

	function claimFXSRewards(address) external;

	function execute(
		address,
		uint256,
		bytes calldata
	) external returns (bool, bytes memory);

	function setGovernance(address) external;

	function voteGaugeWeight(address, uint256) external;

	function setAngleDepositor(address) external;

	function setFxsDepositor(address) external;
}