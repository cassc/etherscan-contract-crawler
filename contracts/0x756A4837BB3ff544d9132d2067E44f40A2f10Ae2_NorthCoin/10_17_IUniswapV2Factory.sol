// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.17;

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}