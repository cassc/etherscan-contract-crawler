// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBPayoutTerminal3_1 {
  function distributePayoutsOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    address _token,
    uint256 _minReturnedTokens,
    bytes calldata _metadata
  ) external returns (uint256 netLeftoverDistributionAmount);
}