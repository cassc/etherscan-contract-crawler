// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMultiFeeDistribution {
  function addReward(address rewardsToken) external;

  function exit(bool claimRewards, address onBehalfOf) external;

  function stake(
    uint256 amount,
    bool lock,
    address onBehalfOf
  ) external;

  function mint(
    address user,
    uint256 amount,
    bool withPenalty
  ) external;
}