// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

interface IStakingPool {
  function lastTimeRewardApplicable() external view returns (uint256);

  function rewardPerToken() external view returns (uint256);

  function earned(address account) external view returns (uint256);

  function getRewardForDuration() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function stake(uint256 amount) external payable;

  function withdraw(uint256 amount) external;

  function getReward() external;
}