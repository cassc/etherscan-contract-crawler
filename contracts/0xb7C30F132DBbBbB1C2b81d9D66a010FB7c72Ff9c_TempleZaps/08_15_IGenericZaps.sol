pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface IGenericZaps {
  function zapIn(
    address fromToken,
    uint256 fromAmount,
    address toToken,
    uint256 amountOutMin,
    address swapTarget,
    bytes calldata swapData
  ) external payable returns (uint256 amountOut);
  function getSwapInAmount(uint256 reserveIn, uint256 userIn) external pure returns (uint256);
}