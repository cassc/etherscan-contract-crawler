// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

struct UserData {
  uint256 index;
  uint256 expectedRewards;
  uint256 claimableRewards;
}

struct AssetData {
  uint256 index;
  uint256 lastAvailableRewards;
  address rewardToken; // The address of reward token
  address yieldAddress; // The address of vault
  mapping(address => UserData) users;
  uint256 claimableIndex;
}

struct AggregatedRewardsData {
  address asset;
  address rewardToken;
  uint256 balance;
}

interface IVariableYieldDistribution {
  function claimRewards(
    address[] calldata assets,
    uint256[] calldata amounts,
    address to
  ) external returns (uint256);

  function getRewardsBalance(address[] calldata assets, address user)
    external
    view
    returns (AggregatedRewardsData[] memory);

  function getAssetData(address asset)
    external
    view
    returns (
      uint256,
      address,
      address,
      uint256
    );

  function getUserAssetData(address user, address asset)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );
}