// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBRedemptionTerminal {
  function redeemTokensOf(
    address holder,
    uint256 projectId,
    uint256 tokenCount,
    address token,
    uint256 minReturnedTokens,
    address payable beneficiary,
    string calldata memo,
    bytes calldata metadata
  ) external returns (uint256 reclaimAmount);
}