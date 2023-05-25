// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

interface IChainlink {
  function decimals() external view returns (uint8);

  function latestAnswer() external view returns (int256);
}