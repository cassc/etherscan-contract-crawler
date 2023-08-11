// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBPayoutTerminal3_1 {
  function distributePayoutsOf(
    uint256 projectId,
    uint256 amount,
    uint256 currency,
    address token,
    uint256 minReturnedTokens,
    bytes calldata metadata
  ) external returns (uint256 netLeftoverDistributionAmount);
}