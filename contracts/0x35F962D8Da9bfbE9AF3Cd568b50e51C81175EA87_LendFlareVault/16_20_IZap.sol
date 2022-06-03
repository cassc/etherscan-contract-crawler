// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IZap {
  function zap(
    address _fromToken,
    uint256 _amountIn,
    address _toToken,
    uint256 _minOut
  ) external payable returns (uint256);
}