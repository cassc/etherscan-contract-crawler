// lightweight version of @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

// SPDX-License-Identifier: GPL-3.0-or-later
// Uniswap Contracts

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}