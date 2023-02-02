// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

interface IUniswapV2Factory
{
	function createPair(address _tokenA, address _tokenB) external returns (address _pair);
}