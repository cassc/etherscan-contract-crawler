// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.19;

interface IUniswapV2Factory {
  function createPair(address tokenA, address tokenB) external returns (address pair);
}