// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

library MultiRewardsDistributionTypes {
  struct AssetConfigInput {
    uint128 emissionPerSecond;
    address rewardAsset;
    uint256 rewardsDuration;
    bool lockRewards;
    uint256 lockStartBlockDelay;
  }

  struct UserStakeInput {
    address rewardAsset;
    uint256 stakedByUser;
    uint256 totalStaked;
  }
}