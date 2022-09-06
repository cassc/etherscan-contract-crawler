// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBarrelX {
	function mintBatchBarrel (uint8 _option, uint256 _amount) payable external;
	function adminMintBatchBarrel (uint8 _option, uint256 _amount) external;
}