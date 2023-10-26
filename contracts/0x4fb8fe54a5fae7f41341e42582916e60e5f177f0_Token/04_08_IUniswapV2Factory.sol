// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

interface IUniswapV2Factory {
	function createPair(address tokenA, address tokenB) external returns (address pair);
}