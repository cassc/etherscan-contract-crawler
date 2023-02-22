// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBFeeHoldingTerminal {
  function addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    bool _shouldRefundHeldFees,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable;
}