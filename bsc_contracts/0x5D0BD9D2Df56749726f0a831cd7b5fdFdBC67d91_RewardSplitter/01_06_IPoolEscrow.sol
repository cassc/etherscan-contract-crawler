// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

interface IPoolEscrow {
  function notifySecondaryTokens(uint256 number) external;
}