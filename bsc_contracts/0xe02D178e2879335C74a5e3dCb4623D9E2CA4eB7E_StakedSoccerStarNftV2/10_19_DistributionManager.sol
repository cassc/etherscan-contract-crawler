// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {SafeMath} from "../lib/SafeMath.sol";
import {DistributionTypes} from "../lib/DistributionTypes.sol";

/**
 * @title DistributionManager
 * @notice Accounting contract to manage multiple staking distributions
 **/
contract DistributionManager is OwnableUpgradeable {
  using SafeMath for uint256;

  struct AssetData {
    uint128 emissionPerSecond;
    uint128 lastUpdateTimestamp;
    uint256 index;
    mapping(uint256 => uint256) tokenDebt;
  }

  uint256 public  DISTRIBUTION_END;

  uint8 public constant PRECISION = 18;

  mapping(address => AssetData) public assets;

  event AssetConfigUpdated(address indexed asset, uint256 emission);
  event AssetIndexUpdated(address indexed asset, uint256 index);
  event UserIndexUpdated(uint indexed tokenId, address indexed asset, uint256 index);

  function setDistributionDuration(uint256 distributionDuration) public onlyOwner{
    DISTRIBUTION_END = block.timestamp.add(distributionDuration);
  }

  /**
   * @dev Configures the distribution of rewards for a list of assets
   * @param assetsConfigInput The list of configurations to apply
   **/
  function configureAssets(DistributionTypes.AssetConfigInput[] calldata assetsConfigInput)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < assetsConfigInput.length; i++) {
      AssetData storage assetConfig = assets[assetsConfigInput[i].underlyingAsset];

      _updateAssetStateInternal(
        assetsConfigInput[i].underlyingAsset,
        assetConfig,
        assetsConfigInput[i].totalPower
      );

      assetConfig.emissionPerSecond = assetsConfigInput[i].emissionPerSecond;

      emit AssetConfigUpdated(
        assetsConfigInput[i].underlyingAsset,
        assetsConfigInput[i].emissionPerSecond
      );
    }
  }

  /**
   * @dev Updates the state of one distribution, mainly rewards index and timestamp
   * @param underlyingAsset The address used as key in the distribution, for example sAAVE or the aTokens addresses on Aave
   * @param assetConfig Storage pointer to the distribution's config
   * @param totalStaked Current total of staked assets for this distribution
   * @return The new distribution index
   **/
  function _updateAssetStateInternal(
    address underlyingAsset,
    AssetData storage assetConfig,
    uint256 totalStaked
  ) internal returns (uint256) {
    uint256 oldIndex = assetConfig.index;
    uint128 lastUpdateTimestamp = assetConfig.lastUpdateTimestamp;

    if (block.timestamp == lastUpdateTimestamp) {
      return oldIndex;
    }

    uint256 newIndex =
      _getAssetIndex(oldIndex, assetConfig.emissionPerSecond, lastUpdateTimestamp, totalStaked);

    if (newIndex != oldIndex) {
      assetConfig.index = newIndex;
      emit AssetIndexUpdated(underlyingAsset, newIndex);
    }

    assetConfig.lastUpdateTimestamp = uint128(block.timestamp);

    return newIndex;
  }

  /**
   * @dev Updates the state of an token in a distribution
   * @param tokenId The token's address
   * @param asset The address of the reference asset of the distribution
   * @param tokenPower Amount of tokens staked by the token in the distribution at the moment
   * @param totalPower Total tokens staked in the distribution
   * @return The accrued rewards for the token until the moment
   **/
  function _updateTokenAssetInternal(
    uint256 tokenId,
    address asset,
    uint256 tokenPower,
    uint256 totalPower
  ) internal returns (uint256) {
    AssetData storage assetData = assets[asset];
    uint256 tokenIndex = assetData.tokenDebt[tokenId];
    uint256 accruedRewards = 0;

    uint256 newIndex = _updateAssetStateInternal(asset, assetData, totalPower);

    if (tokenIndex != newIndex) {
      if (tokenPower != 0) {
        accruedRewards = _getRewards(tokenPower, newIndex, tokenIndex);
      }

      assetData.tokenDebt[tokenId] = newIndex;
      emit UserIndexUpdated(tokenId, asset, newIndex);
    }

    return accruedRewards;
  }

  /**
   * @dev Used by "frontend" stake contracts to update the data of an token when claiming rewards from there
   * @param tokenId The address of the token
   * @param stakes List of structs of the token data related with his stake
   * @return The accrued rewards for the token until the moment
   **/
  function _claimRewards(uint256 tokenId, DistributionTypes.UserStakeInput[] memory stakes)
    internal
    returns (uint256)
  {
    uint256 accruedRewards = 0;

    for (uint256 i = 0; i < stakes.length; i++) {
      accruedRewards = accruedRewards.add(
        _updateTokenAssetInternal(
          tokenId,
          stakes[i].underlyingAsset,
          stakes[i].tokenPower,
          stakes[i].totalPower
        )
      );
    }

    return accruedRewards;
  }

  /**
   * @dev Return the accrued rewards for an token over a list of distribution
   * @param tokenId The address of the token
   * @param stakes List of structs of the token data related with his stake
   * @return The accrued rewards for the token until the moment
   **/
  function _getUnclaimedRewards(uint256 tokenId, DistributionTypes.UserStakeInput[] memory stakes)
    internal
    view
    returns (uint256)
  {
    uint256 accruedRewards = 0;

    for (uint256 i = 0; i < stakes.length; i++) {
      AssetData storage assetConfig = assets[stakes[i].underlyingAsset];
      uint256 assetIndex =
        _getAssetIndex(
          assetConfig.index,
          assetConfig.emissionPerSecond,
          assetConfig.lastUpdateTimestamp,
          stakes[i].totalPower
        );

      accruedRewards = accruedRewards.add(
        _getRewards(stakes[i].tokenPower, assetIndex, assetConfig.tokenDebt[tokenId])
      );
    }
    return accruedRewards;
  }

  /**
   * @dev Internal function for the calculation of token's rewards on a distribution
   * @param principalTotalPower Amount staked by the token on a distribution
   * @param reserveIndex Current index of the distribution
   * @param tokenIndex Index stored for the token, representation his staking moment
   * @return The rewards
   **/
  function _getRewards(
    uint256 principalTotalPower,
    uint256 reserveIndex,
    uint256 tokenIndex
  ) internal pure returns (uint256) {
    return principalTotalPower.mul(reserveIndex.sub(tokenIndex)).div(10**uint256(PRECISION));
  }

  /**
   * @dev Calculates the next value of an specific distribution index, with validations
   * @param currentIndex Current index of the distribution
   * @param emissionPerSecond Representing the total rewards distributed per second per asset unit, on the distribution
   * @param lastUpdateTimestamp Last moment this distribution was updated
   * @param totalPower of tokens considered for the distribution
   * @return The new index.
   **/
  function _getAssetIndex(
    uint256 currentIndex,
    uint256 emissionPerSecond,
    uint128 lastUpdateTimestamp,
    uint256 totalPower
  ) internal view returns (uint256) {
    if (
      emissionPerSecond == 0 ||
      totalPower == 0 ||
      lastUpdateTimestamp == block.timestamp ||
      lastUpdateTimestamp >= DISTRIBUTION_END
    ) {
      return currentIndex;
    }

    uint256 currentTimestamp =
      block.timestamp > DISTRIBUTION_END ? DISTRIBUTION_END : block.timestamp;
    uint256 timeDelta = currentTimestamp.sub(lastUpdateTimestamp);
    return
      emissionPerSecond.mul(timeDelta).mul(10**uint256(PRECISION)).div(totalPower).add(
        currentIndex
      );
  }

  /**
   * @dev Returns the data of an token on a distribution
   * @param tokenId Id of the token
   * @param asset The address of the reference asset of the distribution
   * @return The new index
   **/
  function getTokenAssetData(uint256 tokenId, address asset) public view returns (uint256) {
    return assets[asset].tokenDebt[tokenId];
  }
}