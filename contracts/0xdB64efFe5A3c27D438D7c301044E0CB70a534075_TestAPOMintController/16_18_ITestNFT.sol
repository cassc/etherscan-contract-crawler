// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ITestNFT {
	function mint(address to_, uint256 amount) external;
	function totalSupply() external view returns (uint256);
}