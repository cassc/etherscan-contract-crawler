// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

interface IStakeable {
  function hasStake(address _user) external view returns (bool);

  function getStaked(address _user) external view returns (uint256);

  function getRewards(
    address _user,
    address _rewardToken
  ) external view returns (uint256);

  function getTotalStaked() external view returns (uint256);

  function stake(uint256 amount) external;

  function unstake(uint256 amount) external;

  function claim() external;

  function stake(address _user, uint256 amount) external;

  function claim(address _user) external;
}