// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import {ILendingPoolAddressesProvider} from '../interfaces/ILendingPoolAddressesProvider.sol';
import {ISturdyIncentivesController} from '../interfaces/ISturdyIncentivesController.sol';
import {IUiIncentiveDataProvider} from './interfaces/IUiIncentiveDataProvider.sol';
import {ILendingPool} from '../interfaces/ILendingPool.sol';
import {IAToken} from '../interfaces/IAToken.sol';
import {IVariableDebtToken} from '../interfaces/IVariableDebtToken.sol';
import {IStableDebtToken} from '../interfaces/IStableDebtToken.sol';
import {UserConfiguration} from '../protocol/libraries/configuration/UserConfiguration.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';
import {IERC20Detailed} from '../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IReserveInterestRateStrategy} from '../interfaces/IReserveInterestRateStrategy.sol';
import {IYieldDistribution} from '../interfaces/IYieldDistribution.sol';
import {IStableYieldDistribution} from '../interfaces/IStableYieldDistribution.sol';
import {IVariableYieldDistribution, AggregatedRewardsData} from '../interfaces/IVariableYieldDistribution.sol';
import {IIncentiveVault} from '../interfaces/IIncentiveVault.sol';

contract UiIncentiveDataProvider is IUiIncentiveDataProvider {
  using UserConfiguration for DataTypes.UserConfigurationMap;

  constructor() {}

  function getFullReservesIncentiveData(ILendingPoolAddressesProvider provider, address user)
    external
    view
    override
    returns (AggregatedReserveIncentiveData[] memory, UserReserveIncentiveData[] memory)
  {
    return (_getReservesIncentivesData(provider), _getUserReservesIncentivesData(provider, user));
  }

  function getReservesIncentivesData(ILendingPoolAddressesProvider provider)
    external
    view
    override
    returns (AggregatedReserveIncentiveData[] memory)
  {
    return _getReservesIncentivesData(provider);
  }

  function _getReservesIncentivesData(ILendingPoolAddressesProvider provider)
    private
    view
    returns (AggregatedReserveIncentiveData[] memory)
  {
    ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
    address[] memory reserves = lendingPool.getReservesList();
    uint256 length = reserves.length;
    AggregatedReserveIncentiveData[]
      memory reservesIncentiveData = new AggregatedReserveIncentiveData[](length);

    for (uint256 i; i < length; ++i) {
      AggregatedReserveIncentiveData memory reserveIncentiveData = reservesIncentiveData[i];
      reserveIncentiveData.underlyingAsset = reserves[i];

      DataTypes.ReserveData memory baseData = lendingPool.getReserveData(reserves[i]);

      try IStableDebtToken(baseData.aTokenAddress).getIncentivesController() returns (
        ISturdyIncentivesController aTokenIncentiveController
      ) {
        if (address(aTokenIncentiveController) != address(0)) {
          address aRewardToken = aTokenIncentiveController.REWARD_TOKEN();

          try aTokenIncentiveController.getAssetData(baseData.aTokenAddress) returns (
            uint256 aTokenIncentivesIndex,
            uint256 aEmissionPerSecond,
            uint256 aIncentivesLastUpdateTimestamp
          ) {
            reserveIncentiveData.aIncentiveData = IncentiveData(
              aEmissionPerSecond,
              aIncentivesLastUpdateTimestamp,
              aTokenIncentivesIndex,
              aTokenIncentiveController.DISTRIBUTION_END(),
              baseData.aTokenAddress,
              aRewardToken,
              address(aTokenIncentiveController),
              IERC20Detailed(aRewardToken).decimals(),
              aTokenIncentiveController.PRECISION()
            );
          } catch (
            bytes memory /*lowLevelData*/
          ) {}
        }
      } catch (
        bytes memory /*lowLevelData*/
      ) {
        // Will not get here
      }

      try IStableDebtToken(baseData.stableDebtTokenAddress).getIncentivesController() returns (
        ISturdyIncentivesController sTokenIncentiveController
      ) {
        if (address(sTokenIncentiveController) != address(0)) {
          address sRewardToken = sTokenIncentiveController.REWARD_TOKEN();
          try sTokenIncentiveController.getAssetData(baseData.stableDebtTokenAddress) returns (
            uint256 sTokenIncentivesIndex,
            uint256 sEmissionPerSecond,
            uint256 sIncentivesLastUpdateTimestamp
          ) {
            reserveIncentiveData.sIncentiveData = IncentiveData(
              sEmissionPerSecond,
              sIncentivesLastUpdateTimestamp,
              sTokenIncentivesIndex,
              sTokenIncentiveController.DISTRIBUTION_END(),
              baseData.stableDebtTokenAddress,
              sRewardToken,
              address(sTokenIncentiveController),
              IERC20Detailed(sRewardToken).decimals(),
              sTokenIncentiveController.PRECISION()
            );
          } catch (
            bytes memory /*lowLevelData*/
          ) {}
        }
      } catch (
        bytes memory /*lowLevelData*/
      ) {
        // Will not get here
      }

      try IStableDebtToken(baseData.variableDebtTokenAddress).getIncentivesController() returns (
        ISturdyIncentivesController vTokenIncentiveController
      ) {
        if (address(vTokenIncentiveController) != address(0)) {
          address vRewardToken = vTokenIncentiveController.REWARD_TOKEN();

          try vTokenIncentiveController.getAssetData(baseData.variableDebtTokenAddress) returns (
            uint256 vTokenIncentivesIndex,
            uint256 vEmissionPerSecond,
            uint256 vIncentivesLastUpdateTimestamp
          ) {
            reserveIncentiveData.vIncentiveData = IncentiveData(
              vEmissionPerSecond,
              vIncentivesLastUpdateTimestamp,
              vTokenIncentivesIndex,
              vTokenIncentiveController.DISTRIBUTION_END(),
              baseData.variableDebtTokenAddress,
              vRewardToken,
              address(vTokenIncentiveController),
              IERC20Detailed(vRewardToken).decimals(),
              vTokenIncentiveController.PRECISION()
            );
          } catch (
            bytes memory /*lowLevelData*/
          ) {}
        }
      } catch (
        bytes memory /*lowLevelData*/
      ) {
        // Will not get here
      }

      try
        IReserveInterestRateStrategy(baseData.interestRateStrategyAddress).yieldDistributor()
      returns (address yieldDistributor) {
        if (yieldDistributor != address(0)) {
          // get stable reward data
          try IStableYieldDistribution(yieldDistributor).REWARD_TOKEN() returns (
            address rewardToken
          ) {
            if (rewardToken != address(0)) {
              (
                uint256 tokenIncentivesIndex,
                uint256 emissionPerSecond,
                uint256 incentivesLastUpdateTimestamp
              ) = IStableYieldDistribution(yieldDistributor).getAssetData(baseData.aTokenAddress);

              reserveIncentiveData.rewardData = RewardData(
                // stable reward info
                emissionPerSecond,
                incentivesLastUpdateTimestamp,
                IStableYieldDistribution(yieldDistributor).getDistributionEnd(),
                // variable reward info
                0,
                0,
                // common reward info
                tokenIncentivesIndex,
                baseData.aTokenAddress,
                rewardToken,
                yieldDistributor,
                IERC20Detailed(rewardToken).decimals()
              );
            }
          } catch (
            bytes memory /*lowLevelData*/
          ) {
            // get variable reward data
            (
              uint256 tokenIncentivesIndex,
              address vaultAddress,
              address rewardToken,
              uint256 lastAvailableRewards
            ) = IVariableYieldDistribution(yieldDistributor).getAssetData(baseData.aTokenAddress);
            uint256 incentiveRatio = IIncentiveVault(vaultAddress).getIncentiveRatio();

            reserveIncentiveData.rewardData = RewardData(
              // stable reward info
              0,
              0,
              0,
              // variable reward info
              incentiveRatio,
              lastAvailableRewards,
              // common reward info
              tokenIncentivesIndex,
              baseData.aTokenAddress,
              rewardToken,
              yieldDistributor,
              IERC20Detailed(rewardToken).decimals()
            );
          }
        }
      } catch (
        bytes memory /*lowLevelData*/
      ) {}
    }
    return (reservesIncentiveData);
  }

  function getUserReservesIncentivesData(ILendingPoolAddressesProvider provider, address user)
    external
    view
    override
    returns (UserReserveIncentiveData[] memory)
  {
    return _getUserReservesIncentivesData(provider, user);
  }

  function _getUserReservesIncentivesData(ILendingPoolAddressesProvider provider, address user)
    private
    view
    returns (UserReserveIncentiveData[] memory)
  {
    ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
    address[] memory reserves = lendingPool.getReservesList();
    uint256 length = reserves.length;

    UserReserveIncentiveData[] memory userReservesIncentivesData = new UserReserveIncentiveData[](
      user != address(0) ? length : 0
    );

    for (uint256 i; i < length; ++i) {
      DataTypes.ReserveData memory baseData = lendingPool.getReserveData(reserves[i]);

      // user reserve data
      userReservesIncentivesData[i].underlyingAsset = reserves[i];

      IUiIncentiveDataProvider.UserIncentiveData memory aUserIncentiveData;

      try IAToken(baseData.aTokenAddress).getIncentivesController() returns (
        ISturdyIncentivesController aTokenIncentiveController
      ) {
        if (address(aTokenIncentiveController) != address(0)) {
          address aRewardToken = aTokenIncentiveController.REWARD_TOKEN();
          aUserIncentiveData.tokenincentivesUserIndex = aTokenIncentiveController.getUserAssetData(
            user,
            baseData.aTokenAddress
          );
          aUserIncentiveData.userUnclaimedRewards = aTokenIncentiveController
            .getUserUnclaimedRewards(user);
          aUserIncentiveData.tokenAddress = baseData.aTokenAddress;
          aUserIncentiveData.rewardTokenAddress = aRewardToken;
          aUserIncentiveData.incentiveControllerAddress = address(aTokenIncentiveController);
          aUserIncentiveData.rewardTokenDecimals = IERC20Detailed(aRewardToken).decimals();
        }
      } catch (
        bytes memory /*lowLevelData*/
      ) {}

      userReservesIncentivesData[i].aTokenIncentivesUserData = aUserIncentiveData;

      UserIncentiveData memory vUserIncentiveData;

      try IVariableDebtToken(baseData.variableDebtTokenAddress).getIncentivesController() returns (
        ISturdyIncentivesController vTokenIncentiveController
      ) {
        if (address(vTokenIncentiveController) != address(0)) {
          address vRewardToken = vTokenIncentiveController.REWARD_TOKEN();
          vUserIncentiveData.tokenincentivesUserIndex = vTokenIncentiveController.getUserAssetData(
            user,
            baseData.variableDebtTokenAddress
          );
          vUserIncentiveData.userUnclaimedRewards = vTokenIncentiveController
            .getUserUnclaimedRewards(user);
          vUserIncentiveData.tokenAddress = baseData.variableDebtTokenAddress;
          vUserIncentiveData.rewardTokenAddress = vRewardToken;
          vUserIncentiveData.incentiveControllerAddress = address(vTokenIncentiveController);
          vUserIncentiveData.rewardTokenDecimals = IERC20Detailed(vRewardToken).decimals();
        }
      } catch (
        bytes memory /*lowLevelData*/
      ) {}

      userReservesIncentivesData[i].vTokenIncentivesUserData = vUserIncentiveData;

      UserIncentiveData memory sUserIncentiveData;

      try IStableDebtToken(baseData.stableDebtTokenAddress).getIncentivesController() returns (
        ISturdyIncentivesController sTokenIncentiveController
      ) {
        if (address(sTokenIncentiveController) != address(0)) {
          address sRewardToken = sTokenIncentiveController.REWARD_TOKEN();
          sUserIncentiveData.tokenincentivesUserIndex = sTokenIncentiveController.getUserAssetData(
            user,
            baseData.stableDebtTokenAddress
          );
          sUserIncentiveData.userUnclaimedRewards = sTokenIncentiveController
            .getUserUnclaimedRewards(user);
          sUserIncentiveData.tokenAddress = baseData.stableDebtTokenAddress;
          sUserIncentiveData.rewardTokenAddress = sRewardToken;
          sUserIncentiveData.incentiveControllerAddress = address(sTokenIncentiveController);
          sUserIncentiveData.rewardTokenDecimals = IERC20Detailed(sRewardToken).decimals();
        }
      } catch (
        bytes memory /*lowLevelData*/
      ) {}

      userReservesIncentivesData[i].sTokenIncentivesUserData = sUserIncentiveData;

      try
        IReserveInterestRateStrategy(baseData.interestRateStrategyAddress).yieldDistributor()
      returns (address yieldDistributor) {
        if (yieldDistributor != address(0)) {
          UserRewardData memory rewardUserData;

          // get stable reward user data
          try IStableYieldDistribution(yieldDistributor).REWARD_TOKEN() returns (
            address rewardToken
          ) {
            rewardUserData = _getUserStableRewardData(
              user,
              baseData.aTokenAddress,
              rewardToken,
              yieldDistributor
            );
          } catch (
            bytes memory /*lowLevelData*/
          ) {
            // get variable reward user data
            rewardUserData = _getUserVariableRewardData(
              user,
              baseData.aTokenAddress,
              yieldDistributor
            );
          }

          userReservesIncentivesData[i].rewardUserData = rewardUserData;
        }
      } catch (
        bytes memory /*lowLevelData*/
      ) {}
    }

    return (userReservesIncentivesData);
  }

  function _getUserStableRewardData(
    address user,
    address asset,
    address rewardToken,
    address yieldDistributor
  ) private view returns (UserRewardData memory rewardUserData) {
    rewardUserData.tokenincentivesUserIndex = IStableYieldDistribution(yieldDistributor)
      .getUserAssetData(user, asset);
    address[] memory assets = new address[](1);
    assets[0] = asset;
    rewardUserData.userUnclaimedRewards = IStableYieldDistribution(yieldDistributor)
      .getRewardsBalance(assets, user);
    rewardUserData.tokenAddress = asset;
    rewardUserData.rewardTokenAddress = rewardToken;
    rewardUserData.distributorAddress = yieldDistributor;
    rewardUserData.rewardTokenDecimals = IERC20Detailed(rewardToken).decimals();
  }

  function _getUserVariableRewardData(
    address user,
    address asset,
    address yieldDistributor
  ) private view returns (UserRewardData memory rewardUserData) {
    (rewardUserData.tokenincentivesUserIndex, , ) = IVariableYieldDistribution(yieldDistributor)
      .getUserAssetData(user, asset);
    address[] memory assets = new address[](1);
    assets[0] = asset;
    AggregatedRewardsData[] memory rewardData = IVariableYieldDistribution(yieldDistributor)
      .getRewardsBalance(assets, user);
    rewardUserData.userUnclaimedRewards = rewardData[0].balance;
    rewardUserData.tokenAddress = asset;
    rewardUserData.rewardTokenAddress = rewardData[0].rewardToken;
    rewardUserData.distributorAddress = yieldDistributor;
    rewardUserData.rewardTokenDecimals = IERC20Detailed(rewardData[0].rewardToken).decimals();
  }
}