// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IOpenChests {
	function mint(address to, uint256 chestId) external;
}