// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

interface IStakeable {
  function hasStake(address staker) external view returns (bool);

  function getStaked(address staker) external view returns (uint256);

  function contains(address rewardToken) external view returns (bool);

  function getRewards(
    address staker,
    address rewardToken
  ) external view returns (uint256);

  function getTotalStaked() external view returns (uint256);

  function stake(uint256 amount) external;

  function stake(address staker, uint256 amount) external;

  function unstake(uint256 amount) external;

  function claim() external;

  function claim(address staker) external;

  function claim(address staker, address rewardToken) external;
}