// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBAllowanceTerminal3_1 {
  function useAllowanceOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    address _token,
    uint256 _minReturnedTokens,
    address payable _beneficiary,
    string calldata _memo,
    bytes calldata _metadata
  ) external returns (uint256 netDistributedAmount);
}