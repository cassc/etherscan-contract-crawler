// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.18;

interface IUniswapV2Pair {
  function mint(address to) external returns (uint liquidity);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}