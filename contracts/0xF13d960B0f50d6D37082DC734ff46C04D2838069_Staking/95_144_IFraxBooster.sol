// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface IFraxBooster {
	// Create a vault for the given pool id
	function createVault(uint256 _pid) external returns (address);

	// Pool registry address
	function poolRegistry() external returns (address);
}