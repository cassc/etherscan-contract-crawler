// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IDepositor {
	function deposit(
		uint256 amount,
		bool lock,
		bool stake,
		address user
	) external;

	function minter() external returns (address);
}