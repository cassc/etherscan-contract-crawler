// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

interface ISwapper {
  function swap(
    uint256 _amountIn,
    address _tokenIn,
    address _tokenOut,
    bytes calldata _swapData
  ) external payable returns (uint256 amountOut);
}