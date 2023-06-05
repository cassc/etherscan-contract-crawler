// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.16;

interface IRewards {
  function stake(address, uint256) external;
  function stakeFor(address, uint256) external;
  function withdraw(address, uint256) external;
  function exit(address) external;
  function getReward(address) external;
  function queueNewRewards(uint256) external;
  function notifyRewardAmount(uint256) external;
  function addExtraReward(address) external;
  function extraRewardsLength() external view returns (uint256);
  function stakingToken() external view returns (address);
  function rewardToken() external view returns (address);
  function earned(address account) external view returns (uint256);
}