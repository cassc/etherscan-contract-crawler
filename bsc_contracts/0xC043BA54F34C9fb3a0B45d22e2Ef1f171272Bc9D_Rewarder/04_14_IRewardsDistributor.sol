// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {DistributionTypes} from '../libraries/DistributionTypes.sol';

interface IRewardsDistributor {
  event AssetConfigUpdated(
    address indexed asset,
    address indexed reward,
    uint256 emission,
    uint256 distributionEnd
  );
  event AssetIndexUpdated(address indexed asset, address indexed reward, uint256 index);
  event UserIndexUpdated(
    address indexed user,
    address indexed asset,
    address indexed reward,
    uint256 index
  );

  event RewardsAccrued(address indexed user, address indexed reward, uint256 amount);

  function setDistributionEnd(
    address asset,
    address reward,
    uint32 distributionEnd
  ) external;

  function getDistributionEnd(address asset, address reward) external view returns (uint256);

  function getUserAssetData(
    address user,
    address asset,
    address reward
  ) external view returns (uint256);

  function getRewardsData(address asset, address reward)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  function getRewardsByAsset(address asset) external view returns (address[] memory);

  function getRewardTokens() external view returns (address[] memory);

  function getUserUnclaimedRewardsFromStorage(address user, address reward)
    external
    view
    returns (uint256);

  function getUserRewardsBalance(
    address[] calldata assets,
    address user,
    address reward
  ) external view returns (uint256);

  function getAllUserRewardsBalance(address[] calldata assets, address user)
    external
    view
    returns (address[] memory, uint256[] memory);

  function getAssetDecimals(address asset) external view returns (uint8);
}