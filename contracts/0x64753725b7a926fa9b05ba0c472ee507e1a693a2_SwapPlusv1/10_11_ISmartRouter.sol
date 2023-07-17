// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface ISmartRouter {
  function exactInputStableSwap(
    address[] calldata path,
    uint256[] calldata flag,
    uint256 amountIn,
    uint256 amountOutMin,
    address to
  ) external payable  returns (uint256 amountOut);
  function exactOutputStableSwap(
    address[] calldata path,
    uint256[] calldata flag,
    uint256 amountOut,
    uint256 amountInMax,
    address to
  ) external payable returns (uint256 amountIn);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to
  ) external payable returns (uint256 amountOut);
  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to
  ) external payable returns (uint256 amountIn);

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
  struct ExactOutputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountOut;
    uint256 amountInMaximum;
    uint160 sqrtPriceLimitX96;
  }
  struct ExactOutputParams {
    bytes path;
    address recipient;
    uint256 amountOut;
    uint256 amountInMaximum;
  }
  function exactInputSingle(ExactInputSingleParams memory params)
    external
    payable
    returns (uint256 amountOut);
  function exactInput(ExactInputParams memory params) external payable returns (uint256 amountOut);
  function exactOutputSingle(ExactOutputSingleParams calldata params)
    external
    payable
    returns (uint256 amountIn);
  function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}