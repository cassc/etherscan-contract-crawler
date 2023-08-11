// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBFeeHoldingTerminal {
  function addToBalanceOf(
    uint256 projectId,
    uint256 amount,
    address token,
    bool shouldRefundHeldFees,
    string calldata memo,
    bytes calldata metadata
  ) external payable;
}