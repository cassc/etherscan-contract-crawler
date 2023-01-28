// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPoolEscrow {
  function notifySecondaryTokens(uint256 number) external;
}