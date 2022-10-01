// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IUniswapV3Twap {
  function estimateAmountOut(address tokenIn, uint128 amountIn, uint32 secondsAgo) external view returns (uint amountOut, uint8 decimalsOut);
}