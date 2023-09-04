// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IShares {
	function burn(uint256) external;

	function totalShares() external view returns (uint256);
}