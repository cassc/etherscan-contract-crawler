//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IKawi {
	function balanceOf(address account) external view returns (uint256);
	function transferFrom(address from, address to, uint256 value) external returns (bool);
	function excludeAccount(address account) external;
	function includeAccount(address account) external;
	function transferOwnership(address newOwner) external;
}