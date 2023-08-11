// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBAllowanceTerminal3_1 {
  function useAllowanceOf(
    uint256 projectId,
    uint256 amount,
    uint256 currency,
    address token,
    uint256 minReturnedTokens,
    address payable beneficiary,
    string calldata memo,
    bytes calldata metadata
  ) external returns (uint256 netDistributedAmount);
}