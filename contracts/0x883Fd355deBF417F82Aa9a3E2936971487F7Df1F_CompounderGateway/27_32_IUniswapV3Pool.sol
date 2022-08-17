// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IUniswapV3Pool {
  function token0() external returns (address);

  function token1() external returns (address);

  function fee() external returns (uint24);
}