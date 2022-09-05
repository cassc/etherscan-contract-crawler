// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJupiterNFT {
	function mint(address _to) external;
	function mintBatch(address _to, uint _amount) external;
}