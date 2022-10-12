// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;
interface PancakeFactory {
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface PancakeRouter {
  function factory() external pure returns (address);
}