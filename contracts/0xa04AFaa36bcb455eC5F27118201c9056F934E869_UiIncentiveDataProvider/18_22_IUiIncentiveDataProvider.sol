// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {ILendingPoolAddressesProvider} from '../../interfaces/ILendingPoolAddressesProvider.sol';

interface IUiIncentiveDataProvider {
  struct AggregatedReserveIncentiveData {
    address underlyingAsset;
    IncentiveData aIncentiveData;
    IncentiveData vIncentiveData;
    IncentiveData sIncentiveData;
    StableRewardData[] stableRewardDatas;
    VariableRewardData variableRewardData;
  }

  struct IncentiveData {
    uint256 emissionPerSecond;
    uint256 incentivesLastUpdateTimestamp;
    uint256 tokenIncentivesIndex;
    uint256 emissionEndTimestamp;
    address tokenAddress;
    address rewardTokenAddress;
    address incentiveControllerAddress;
    uint8 rewardTokenDecimals;
    uint8 precision;
  }

  struct StableRewardData {
    // stable reward info
    uint256 emissionPerSecond;
    uint256 incentivesLastUpdateTimestamp;
    uint256 emissionEndTimestamp;
    // common reward info
    uint256 tokenIncentivesIndex;
    address tokenAddress;
    address rewardTokenAddress;
    address distributorAddress;
    uint8 rewardTokenDecimals;
  }

  struct VariableRewardData {
    // variable reward info
    uint256 incentiveRatio;
    uint256 lastAvailableRewards;
    // common reward info
    uint256 tokenIncentivesIndex;
    address tokenAddress;
    address rewardTokenAddress;
    address distributorAddress;
    uint8 rewardTokenDecimals;
  }

  struct UserReserveIncentiveData {
    address underlyingAsset;
    UserIncentiveData aTokenIncentivesUserData;
    UserIncentiveData vTokenIncentivesUserData;
    UserIncentiveData sTokenIncentivesUserData;
    UserRewardData[] stableRewardUserDatas;
    UserRewardData variableRewardUserData;
  }

  struct UserIncentiveData {
    uint256 tokenincentivesUserIndex;
    uint256 userUnclaimedRewards;
    address tokenAddress;
    address rewardTokenAddress;
    address incentiveControllerAddress;
    uint8 rewardTokenDecimals;
  }

  struct UserRewardData {
    uint256 tokenincentivesUserIndex;
    uint256 userUnclaimedRewards;
    address tokenAddress;
    address rewardTokenAddress;
    address distributorAddress;
    uint8 rewardTokenDecimals;
  }

  function getReservesIncentivesData(
    ILendingPoolAddressesProvider provider
  ) external view returns (AggregatedReserveIncentiveData[] memory);

  function getUserReservesIncentivesData(
    ILendingPoolAddressesProvider provider,
    address user
  ) external view returns (UserReserveIncentiveData[] memory);

  // generic method with full data
  function getFullReservesIncentiveData(
    ILendingPoolAddressesProvider provider,
    address user
  )
    external
    view
    returns (AggregatedReserveIncentiveData[] memory, UserReserveIncentiveData[] memory);
}