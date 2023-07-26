// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

interface IRewardBooster {
  function assertStakeCount(address user) external view;
  function delegateZapStake(address user, uint256 amount) external;
  function getUserBoostRate(address user, uint256 ethxAmount) external view returns (uint256);
}