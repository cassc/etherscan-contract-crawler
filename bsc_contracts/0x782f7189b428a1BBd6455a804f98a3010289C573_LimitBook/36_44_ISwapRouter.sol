// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

interface ISwapRouter {
  struct SwapGivenInInput {
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint24 poolFee;
  }

  struct SwapGivenOutInput {
    address tokenIn;
    address tokenOut;
    uint256 amountOut;
    uint256 amountInMaximum;
    uint24 poolFee;
  }

  function swapGivenIn(
    SwapGivenInInput memory input
  ) external returns (uint256);

  function swapGivenOut(
    SwapGivenOutInput memory input
  ) external returns (uint256);

  function getAmountGivenIn(
    SwapGivenInInput memory input
  ) external view returns (uint256);

  function getAmountGivenOut(
    SwapGivenOutInput memory input
  ) external view returns (uint256);
}