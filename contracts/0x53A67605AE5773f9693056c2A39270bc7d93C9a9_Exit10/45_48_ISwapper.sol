// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

interface ISwapper {
  struct SwapParameters {
    address recipient;
    address tokenIn;
    address tokenOut;
    uint24 fee;
    uint256 amountIn;
    uint16 slippage;
    uint32 oracleSeconds;
  }

  function swap(SwapParameters memory params) external returns (uint256 amountOut);
}