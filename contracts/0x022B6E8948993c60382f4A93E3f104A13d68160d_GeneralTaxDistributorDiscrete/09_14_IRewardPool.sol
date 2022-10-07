// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardPool {
  function addMarginalReward(address rewardToken) external returns (uint256);
  function addMarginalRewardToPool(address poolId, address rewardToken) external returns (uint256);
}