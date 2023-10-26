// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

interface IZap {
	function zapInETH(address) external payable returns (uint, uint);
}