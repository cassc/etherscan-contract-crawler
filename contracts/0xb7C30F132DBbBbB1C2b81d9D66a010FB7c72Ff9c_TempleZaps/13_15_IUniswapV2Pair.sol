pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112, uint112, uint32);
}