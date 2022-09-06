// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IConvexCRVDepositor {
  function deposit(
    uint256 _amount,
    bool _lock,
    address _stakeAddress
  ) external;

  function deposit(uint256 _amount, bool _lock) external;

  function lockIncentive() external view returns (uint256);
}