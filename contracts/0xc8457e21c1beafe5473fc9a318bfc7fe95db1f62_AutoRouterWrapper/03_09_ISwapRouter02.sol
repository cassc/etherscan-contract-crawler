// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import "./IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
  struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
  }
  struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
  }

  function exactInput(ExactInputParams memory params)
    external
    payable
    returns (uint256 amountOut);

  function exactInputSingle(ExactInputSingleParams calldata params)
    external
    payable
    returns (uint256 amountOut);

  function multicall(uint256 deadline, bytes[] calldata data)
    external
    payable
    returns (bytes[] memory);

  function sweepToken(
    address token,
    uint256 amountMinimum,
    address recipient
  ) external payable;

  function unwrapWETH9WithFee(
    uint256 amountMinimum,
    address recipient,
    uint256 feeBips,
    address feeRecipient
  ) external payable;

  function wrapETH(uint256 value) external payable;

  function unwrapWETH9(uint256 amountMinimum) external payable;

  function WETH9() external view returns (address payable);

  //V2 Periphery
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to
  ) external payable returns (uint256 amountOut);
}