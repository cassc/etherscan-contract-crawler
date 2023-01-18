// SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;

interface IOracleRegistry {
  function convert(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256 amountOut);
}