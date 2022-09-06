// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IVeSDT {
	function deposit_for(address _addr, uint256 _value) external;

	function balanceOf(address _addr) external returns (uint256);
}