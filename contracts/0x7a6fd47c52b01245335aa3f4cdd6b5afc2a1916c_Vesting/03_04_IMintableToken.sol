// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @dev Interface for a token that will allow mints from a vesting contract
 */
interface IMintableToken {
	function mint(address to, uint256 amount) external;
}