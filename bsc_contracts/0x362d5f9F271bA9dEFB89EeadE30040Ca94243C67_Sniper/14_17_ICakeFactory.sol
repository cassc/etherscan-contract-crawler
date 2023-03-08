//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICakeFactory {
	function getPair(
		address tokenA,
		address tokenB
	) external view returns (address pair);
}