// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICrossmintable {
	function crossmintMint(address mintTo, uint256 quantity) external payable;
}