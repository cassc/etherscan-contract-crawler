// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.16;

interface IStaker {
  function queueRewards(address rewardToken, uint256 amount) external returns (bool);

  function stake(uint256 amount, address receiver) external returns (uint256);
}