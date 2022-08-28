// lightweight version of @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

// SPDX-License-Identifier: GPL-3.0-or-later
// Uniswap Contracts

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
  function balanceOf(address owner) external view returns (uint);

  function token0() external view returns (address);
  function token1() external view returns (address);
}