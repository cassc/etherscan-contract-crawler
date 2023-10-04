// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IAntiMevStrategy {
  function onTransfer(
    address from,
    address to,
    bool fromIsWhitelisted,
    bool toIsWhitelisted,
    uint256 amount,
    bool isTaxingInProgress
  ) external;
}