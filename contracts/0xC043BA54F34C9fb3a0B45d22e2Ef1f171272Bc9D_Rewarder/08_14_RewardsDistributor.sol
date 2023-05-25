// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {IRewardsDistributor} from './interfaces/IRewardsDistributor.sol';
import {IERC20Detailed} from './interfaces/IERC20Detailed.sol';
import {DistributionTypes} from './libraries/DistributionTypes.sol';
import {Ownable} from './libraries/Ownable.sol';

abstract contract RewardsDistributor is IRewardsDistributor, Ownable {
	struct RewardData {
		uint88 emissionPerSecond;
		uint104 index;
		uint32 lastUpdateTimestamp;
		uint32 distributionEnd;
		mapping(address => uint256) usersIndex;
	}

	struct AssetData {
		// reward => rewardData
		mapping(address => RewardData) rewards;
		address[] availableRewards;
		uint8 decimals;
	}

	// incentivized asset => AssetData
	mapping(address => AssetData) internal _assets;

	// user => reward => unclaimed rewards
	mapping(address => mapping(address => uint256)) internal _usersUnclaimedRewards;

	// reward => isEnabled
	mapping(address => bool) internal _isRewardEnabled;

	address[] internal _rewardTokens;

  function getRewardsData(address asset, address reward)
    public
    view
    override
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return (
      _assets[asset].rewards[reward].index,
      _assets[asset].rewards[reward].emissionPerSecond,
      _assets[asset].rewards[reward].lastUpdateTimestamp,
      _assets[asset].rewards[reward].distributionEnd
    );
  }

  function getDistributionEnd(address asset, address reward)
    external
    view
    override
    returns (uint256)
  {
    return _assets[asset].rewards[reward].distributionEnd;
  }

  function getRewardsByAsset(address asset) external view override returns (address[] memory) {
    return _assets[asset].availableRewards;
  }

  function getRewardTokens() external view override returns (address[] memory) {
    return _rewardTokens;
  }

  function getUserAssetData(
    address user,
    address asset,
    address reward
  ) public view override returns (uint256) {
    return _assets[asset].rewards[reward].usersIndex[user];
  }

  function getUserUnclaimedRewardsFromStorage(address user, address reward)
    external
    view
    override
    returns (uint256)
  {
    return _usersUnclaimedRewards[user][reward];
  }

  function getUserRewardsBalance(
    address[] calldata assets,
    address user,
    address reward
  ) external view override returns (uint256) {
    return _getUserReward(user, reward, _getUserStake(assets, user));
  }

  function getAllUserRewardsBalance(address[] calldata assets, address user)
    external
    view
    override
    returns (address[] memory rewardTokens, uint256[] memory unclaimedAmounts)
  {
    return _getAllUserRewards(user, _getUserStake(assets, user));
  }

  function setDistributionEnd(
    address asset,
    address reward,
    uint32 distributionEnd
  ) external override onlyOwner {
    _assets[asset].rewards[reward].distributionEnd = distributionEnd;

    emit AssetConfigUpdated(
      asset,
      reward,
      _assets[asset].rewards[reward].emissionPerSecond,
      distributionEnd
    );
  }

  function _configureAssets(DistributionTypes.RewardsConfigInput[] memory rewardsInput)
    internal
  {
    for (uint256 i = 0; i < rewardsInput.length; i++) {
      _assets[rewardsInput[i].asset].decimals = IERC20Detailed(rewardsInput[i].asset).decimals();

      RewardData storage rewardConfig = _assets[rewardsInput[i].asset].rewards[
        rewardsInput[i].reward
      ];

      // Add reward address to asset available rewards if latestUpdateTimestamp is zero
      if (rewardConfig.lastUpdateTimestamp == 0) {
        _assets[rewardsInput[i].asset].availableRewards.push(rewardsInput[i].reward);
      }

      // Add reward address to global rewards list if still not enabled
      if (_isRewardEnabled[rewardsInput[i].reward] == false) {
        _isRewardEnabled[rewardsInput[i].reward] = true;
        _rewardTokens.push(rewardsInput[i].reward);
      }

      // Due emissions is still zero, updates only latestUpdateTimestamp
      _updateAssetStateInternal(
        rewardsInput[i].asset,
        rewardsInput[i].reward,
        rewardConfig,
        rewardsInput[i].totalSupply,
        _assets[rewardsInput[i].asset].decimals
      );

      // Configure emission and distribution end of the reward per asset
      rewardConfig.emissionPerSecond = rewardsInput[i].emissionPerSecond;
      rewardConfig.distributionEnd = rewardsInput[i].distributionEnd;

      emit AssetConfigUpdated(
        rewardsInput[i].asset,
        rewardsInput[i].reward,
        rewardsInput[i].emissionPerSecond,
        rewardsInput[i].distributionEnd
      );
    }
  }

  function _updateAssetStateInternal(
    address asset,
    address reward,
    RewardData storage rewardConfig,
    uint256 totalSupply,
    uint8 decimals
  ) internal returns (uint256) {
    uint256 oldIndex = rewardConfig.index;

    if (block.timestamp == rewardConfig.lastUpdateTimestamp) {
      return oldIndex;
    }

    uint256 newIndex = _getAssetIndex(
      oldIndex,
      rewardConfig.emissionPerSecond,
      rewardConfig.lastUpdateTimestamp,
      rewardConfig.distributionEnd,
      totalSupply,
      decimals
    );

    if (newIndex != oldIndex) {
      require(newIndex <= type(uint104).max, 'Index overflow');
      //optimization: storing one after another saves one SSTORE
      rewardConfig.index = uint104(newIndex);
      rewardConfig.lastUpdateTimestamp = uint32(block.timestamp);
      emit AssetIndexUpdated(asset, reward, newIndex);
    } else {
      rewardConfig.lastUpdateTimestamp = uint32(block.timestamp);
    }

    return newIndex;
  }

  function _updateUserRewardsInternal(
    address user,
    address asset,
    address reward,
    uint256 userBalance,
    uint256 totalSupply
  ) internal returns (uint256) {
    RewardData storage rewardData = _assets[asset].rewards[reward];
    uint256 userIndex = rewardData.usersIndex[user];
    uint256 accruedRewards = 0;

    uint256 newIndex = _updateAssetStateInternal(
      asset,
      reward,
      rewardData,
      totalSupply,
      _assets[asset].decimals
    );

    if (userIndex != newIndex) {
      if (userBalance != 0) {
        accruedRewards = _getRewards(userBalance, newIndex, userIndex, _assets[asset].decimals);
      }

      rewardData.usersIndex[user] = newIndex;
      emit UserIndexUpdated(user, asset, reward, newIndex);
    }

    return accruedRewards;
  }

  function _updateUserRewardsPerAssetInternal(
    address asset,
    address user,
    uint256 userBalance,
    uint256 totalSupply
  ) internal {
    for (uint256 r = 0; r < _assets[asset].availableRewards.length; r++) {
      address reward = _assets[asset].availableRewards[r];
      uint256 accruedRewards = _updateUserRewardsInternal(
        user,
        asset,
        reward,
        userBalance,
        totalSupply
      );
      if (accruedRewards != 0) {
        _usersUnclaimedRewards[user][reward] += accruedRewards;

        emit RewardsAccrued(user, reward, accruedRewards);
      }
    }
  }

  function _distributeRewards(
    address user,
    DistributionTypes.UserAssetInput[] memory userState
  ) internal {
    for (uint256 i = 0; i < userState.length; i++) {
      _updateUserRewardsPerAssetInternal(
        userState[i].underlyingAsset,
        user,
        userState[i].userBalance,
        userState[i].totalSupply
      );
    }
  }

  function _getUserReward(
    address user,
    address reward,
    DistributionTypes.UserAssetInput[] memory userState
  ) internal view returns (uint256 unclaimedRewards) {
    // Add unrealized rewards
    for (uint256 i = 0; i < userState.length; i++) {
      if (userState[i].userBalance == 0) {
        continue;
      }
      unclaimedRewards += _getUnrealizedRewardsFromStake(user, reward, userState[i]);
    }

    // Return unrealized rewards plus stored unclaimed rewardss
    return unclaimedRewards + _usersUnclaimedRewards[user][reward];
  }

  function _getAllUserRewards(
    address user,
    DistributionTypes.UserAssetInput[] memory userState
  ) internal view returns (address[] memory rewardTokens, uint256[] memory unclaimedRewards) {
    rewardTokens = new address[](_rewardTokens.length);
    unclaimedRewards = new uint256[](rewardTokens.length);

    // Add stored rewards from user to unclaimedRewards
    for (uint256 y = 0; y < rewardTokens.length; y++) {
      rewardTokens[y] = _rewardTokens[y];
      unclaimedRewards[y] = _usersUnclaimedRewards[user][rewardTokens[y]];
    }

    // Add unrealized rewards from user to unclaimedRewards
    for (uint256 i = 0; i < userState.length; i++) {
      if (userState[i].userBalance == 0) {
        continue;
      }
      for (uint256 r = 0; r < rewardTokens.length; r++) {
        unclaimedRewards[r] += _getUnrealizedRewardsFromStake(user, rewardTokens[r], userState[i]);
      }
    }
    return (rewardTokens, unclaimedRewards);
  }

  function _getUnrealizedRewardsFromStake(
    address user,
    address reward,
    DistributionTypes.UserAssetInput memory stake
  ) internal view returns (uint256) {
    RewardData storage rewardData = _assets[stake.underlyingAsset].rewards[reward];
    uint8 assetDecimals = _assets[stake.underlyingAsset].decimals;
    uint256 assetIndex = _getAssetIndex(
      rewardData.index,
      rewardData.emissionPerSecond,
      rewardData.lastUpdateTimestamp,
      rewardData.distributionEnd,
      stake.totalSupply,
      assetDecimals
    );

    return _getRewards(stake.userBalance, assetIndex, rewardData.usersIndex[user], assetDecimals);
  }

	function _getRewards(
    uint256 principalUserBalance,
    uint256 reserveIndex,
    uint256 userIndex,
    uint8 decimals
  ) internal pure returns (uint256) {
    return (principalUserBalance * (reserveIndex - userIndex)) / 10**decimals;
  }

  function _getAssetIndex(
    uint256 currentIndex,
    uint256 emissionPerSecond,
    uint128 lastUpdateTimestamp,
    uint256 distributionEnd,
    uint256 totalBalance,
    uint8 decimals
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
    uint256 timeDelta = currentTimestamp - lastUpdateTimestamp;
    return (emissionPerSecond * timeDelta * (10**decimals)) / totalBalance + currentIndex;
  }

  function _getUserStake(address[] calldata assets, address user)
    internal
    view
    virtual
    returns (DistributionTypes.UserAssetInput[] memory userState);

  function getAssetDecimals(address asset) external view override returns (uint8) {
    return _assets[asset].decimals;
  }
}