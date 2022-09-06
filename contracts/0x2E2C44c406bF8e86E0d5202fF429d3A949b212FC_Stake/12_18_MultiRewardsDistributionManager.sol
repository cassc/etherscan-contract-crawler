// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {SafeMath} from '../lib/SafeMath.sol';
import {MultiRewardsDistributionTypes} from '../lib/MultiRewardsDistributionTypes.sol';
import {EnumerableSet} from '../lib/EnumerableSet.sol';
import {IRewardLocker} from '../interfaces/IRewardLocker.sol';
import {IERC20} from '../interfaces/IERC20.sol';

/**
 * @title MultiRewardsDistributionManager
 * @notice Accounting contract to manage multiple rewards distributions
 **/
abstract contract MultiRewardsDistributionManager {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  struct AssetData {
    uint128 emissionPerSecond;
    uint128 lastUpdateTimestamp;
    uint256 index;
    mapping(address => uint256) userIndexes;
    uint256 distributionEnd;
    bool lockRewards; // whether reward will be locked for some period of time
    uint256 lockStartBlockDelay; // amount of blocks the schedule will wait until start unlocking rewards linearly
  }

  struct AssetConfig {
    uint128 emissionPerSecond;
    uint256 distributionEnd;
    bool lockRewards;
    uint256 lockStartBlockDelay;
  }

  uint8 public constant PRECISION = 18;

  address public immutable EMISSION_MANAGER;
  IRewardLocker public immutable REWARD_LOCKER;

  EnumerableSet.AddressSet internal _rewardAssets;
  mapping(address => AssetData) public assetsData;

  event AssetConfigUpdated(
    address indexed asset,
    uint256 emission,
    uint256 duration,
    bool lockRewards,
    uint256 lockStartBlockDelay
  );
  event AssetIndexUpdated(address indexed asset, uint256 index);
  event UserIndexUpdated(address indexed user, address indexed asset, uint256 index);

  constructor(address emissionManager, address rewardLocker) {
    EMISSION_MANAGER = emissionManager;
    REWARD_LOCKER = IRewardLocker(rewardLocker);
  }

  /**
   * @dev Configures the distribution of a list of rewards assets
   * @param newConfigs The list of configurations to apply
   **/
  function configureAssets(MultiRewardsDistributionTypes.AssetConfigInput[] calldata newConfigs)
    external
  {
    require(msg.sender == EMISSION_MANAGER, 'ONLY_EMISSION_MANAGER');

    for (uint256 i = 0; i < newConfigs.length; i++) {
      // Intentionally do not check the add() result. It is ok if the asset is already included
      _rewardAssets.add(newConfigs[i].rewardAsset);

      AssetData storage assetConfig = assetsData[newConfigs[i].rewardAsset];

      _updateAssetStateInternal(newConfigs[i].rewardAsset, assetConfig, _getTotalStaked());

      assetConfig.emissionPerSecond = newConfigs[i].emissionPerSecond;
      assetConfig.distributionEnd = block.timestamp.add(newConfigs[i].rewardsDuration);
      assetConfig.lockRewards = newConfigs[i].lockRewards;
      assetConfig.lockStartBlockDelay = newConfigs[i].lockStartBlockDelay;

      if (
        address(REWARD_LOCKER) != address(0) &&
        IERC20(newConfigs[i].rewardAsset).allowance(address(this), address(REWARD_LOCKER)) == 0
      ) {
        IERC20(newConfigs[i].rewardAsset).approve(address(REWARD_LOCKER), type(uint256).max);
      }

      emit AssetConfigUpdated(
        newConfigs[i].rewardAsset,
        newConfigs[i].emissionPerSecond,
        newConfigs[i].rewardsDuration,
        newConfigs[i].lockRewards,
        newConfigs[i].lockStartBlockDelay
      );
    }
  }

  /**
   * @dev Enumerate the configured reward assets
   * @return An array of reward token addresses
   */
  function getRewardAssets() external view returns (address[] memory) {
    uint256 length = _rewardAssets.length();
    address[] memory list = new address[](length);

    for (uint256 i = 0; i < length; i++) {
      list[i] = _rewardAssets.at(i);
    }

    return list;
  }

  /**
   * @dev Returns the data of an user on a distribution
   * @param user Address of the user
   * @param asset The address of the reference asset of the distribution
   * @return The new index
   **/
  function getUserAssetData(address user, address asset) public view returns (uint256) {
    return assetsData[asset].userIndexes[user];
  }

  /**
   * @dev Returns the config of a reward asset
   * @param asset The address of the reward asset
   * @return struct containing asset distribution
   **/
  function getAssetConfig(address asset) external view returns (AssetConfig memory) {
    AssetData storage data = assetsData[asset];

    return
      AssetConfig(
        data.emissionPerSecond,
        data.distributionEnd,
        data.lockRewards,
        data.lockStartBlockDelay
      );
  }

  /**
   * @dev Updates the state of one distribution, mainly rewards index and timestamp
   * @param rewardAsset The address of the reward asset
   * @param assetConfig Storage pointer to the distribution's config
   * @param totalStaked Current total of staked assets
   * @return The new distribution index
   **/
  function _updateAssetStateInternal(
    address rewardAsset,
    AssetData storage assetConfig,
    uint256 totalStaked
  ) internal returns (uint256) {
    uint256 oldIndex = assetConfig.index;
    uint128 lastUpdateTimestamp = assetConfig.lastUpdateTimestamp;

    if (block.timestamp == lastUpdateTimestamp) {
      return oldIndex;
    }

    uint256 newIndex = _getAssetIndex(
      oldIndex,
      assetConfig.emissionPerSecond,
      lastUpdateTimestamp,
      totalStaked,
      assetConfig.distributionEnd
    );

    if (newIndex != oldIndex) {
      assetConfig.index = newIndex;
      emit AssetIndexUpdated(rewardAsset, newIndex);
    }

    assetConfig.lastUpdateTimestamp = uint128(block.timestamp);

    return newIndex;
  }

  /**
   * @dev Updates the state of an user in a distribution
   * @param user The user's address
   * @param asset The address of the reward asset
   * @param stakedByUser Amount of tokens staked by the user at the moment
   * @param totalStaked Total tokens staked
   * @return The accrued rewards for the user until the moment
   **/
  function _updateUserAssetInternal(
    address user,
    address asset,
    uint256 stakedByUser,
    uint256 totalStaked
  ) internal returns (uint256) {
    AssetData storage assetData = assetsData[asset];
    uint256 userIndex = assetData.userIndexes[user];
    uint256 accruedRewards = 0;

    uint256 newIndex = _updateAssetStateInternal(asset, assetData, totalStaked);

    if (userIndex != newIndex) {
      if (stakedByUser != 0) {
        accruedRewards = _getRewards(stakedByUser, newIndex, userIndex);
      }

      assetData.userIndexes[user] = newIndex;
      emit UserIndexUpdated(user, asset, newIndex);
    }

    return accruedRewards;
  }

  /**
   * @dev Return the accrued rewards of a reward asset for an user
   * @param user The address of the user
   * @param stake Struct of the user data related with his stake
   * @return The accrued rewards for the user until the moment
   **/
  function _getUnclaimedRewards(
    address user,
    MultiRewardsDistributionTypes.UserStakeInput memory stake
  ) internal view returns (uint256) {
    uint256 accruedRewards = 0;

    AssetData storage assetConfig = assetsData[stake.rewardAsset];
    uint256 assetIndex = _getAssetIndex(
      assetConfig.index,
      assetConfig.emissionPerSecond,
      assetConfig.lastUpdateTimestamp,
      stake.totalStaked,
      assetConfig.distributionEnd
    );

    accruedRewards = accruedRewards.add(
      _getRewards(stake.stakedByUser, assetIndex, assetConfig.userIndexes[user])
    );

    return accruedRewards;
  }

  /**
   * @dev Internal function for the calculation of user's rewards on a distribution
   * @param principalUserBalance Amount staked by the user on a distribution
   * @param reserveIndex Current index of the distribution
   * @param userIndex Index stored for the user, representation his staking moment
   * @return The rewards
   **/
  function _getRewards(
    uint256 principalUserBalance,
    uint256 reserveIndex,
    uint256 userIndex
  ) internal pure returns (uint256) {
    return principalUserBalance.mul(reserveIndex.sub(userIndex)).div(10**uint256(PRECISION));
  }

  /**
   * @dev Calculates the next value of an specific distribution index, with validations
   * @param currentIndex Current index of the distribution
   * @param emissionPerSecond Representing the total rewards distributed per second per asset unit
   * @param lastUpdateTimestamp Last moment this distribution was updated
   * @param totalBalance of tokens considered for the distribution
   * @return The new index.
   **/
  function _getAssetIndex(
    uint256 currentIndex,
    uint256 emissionPerSecond,
    uint128 lastUpdateTimestamp,
    uint256 totalBalance,
    uint256 distributionEnd
  ) internal view returns (uint256) {
    if (
      emissionPerSecond == 0 ||
      totalBalance == 0 ||
      lastUpdateTimestamp == block.timestamp ||
      lastUpdateTimestamp >= distributionEnd
    ) {
      return currentIndex;
    }

    uint256 currentTimestamp = block.timestamp > distributionEnd
      ? distributionEnd
      : block.timestamp;
    uint256 timeDelta = currentTimestamp.sub(lastUpdateTimestamp);
    return
      emissionPerSecond.mul(timeDelta).mul(10**uint256(PRECISION)).div(totalBalance).add(
        currentIndex
      );
  }

  /**
   * @dev Returns the total staked in the contract
   * @return The amount of total tokens staked
   **/
  function _getTotalStaked() internal view virtual returns (uint256);
}