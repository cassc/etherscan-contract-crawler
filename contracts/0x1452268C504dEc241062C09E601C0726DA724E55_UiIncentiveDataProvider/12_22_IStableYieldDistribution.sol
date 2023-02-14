// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IStableYieldDistribution {
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to
  ) external returns (uint256);

  function getRewardsBalance(address[] calldata assets, address user)
    external
    view
    returns (uint256);

  function REWARD_TOKEN() external view returns (address);

  function getDistributionEnd() external view returns (uint256);

  function getAssetData(address asset)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function getUserAssetData(address user, address asset) external view returns (uint256);
}