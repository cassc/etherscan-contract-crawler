// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20Detailed} from '../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {ILendingPoolAddressesProvider} from '../interfaces/ILendingPoolAddressesProvider.sol';
import {IViniumIncentivesController} from '../interfaces/IViniumIncentivesController.sol';
import {IUiPoolDataProvider} from './interfaces/IUiPoolDataProvider.sol';
import {ILendingPool} from '../interfaces/ILendingPool.sol';
import {IPriceOracleGetter} from '../interfaces/IPriceOracleGetter.sol';
import {IViToken} from '../interfaces/IViToken.sol';
import {IVariableVdToken} from '../interfaces/IVariableVdToken.sol';
import {IStableVdToken} from '../interfaces/IStableVdToken.sol';
import {WadRayMath} from '../protocol/libraries/math/WadRayMath.sol';
import {ReserveConfiguration} from '../protocol/libraries/configuration/ReserveConfiguration.sol';
import {UserConfiguration} from '../protocol/libraries/configuration/UserConfiguration.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';
import {DefaultReserveInterestRateStrategy} from '../protocol/lendingpool/DefaultReserveInterestRateStrategy.sol';

contract UiPoolDataProvider is IUiPoolDataProvider {
  using WadRayMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  address public constant MOCK_USD_ADDRESS = 0x10F7Fc1F91Ba351f9C629c5947AD69bD03C05b96;
  IViniumIncentivesController public immutable override incentivesController;
  IPriceOracleGetter public immutable oracle;

  constructor(IViniumIncentivesController _incentivesController, IPriceOracleGetter _oracle)
    public
  {
    incentivesController = _incentivesController;
    oracle = _oracle;
  }

  function getInterestRateStrategySlopes(DefaultReserveInterestRateStrategy interestRateStrategy)
    internal
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return (
      interestRateStrategy.variableRateSlope1(),
      interestRateStrategy.variableRateSlope2(),
      interestRateStrategy.stableRateSlope1(),
      interestRateStrategy.stableRateSlope2()
    );
  }

  function getReservesList(ILendingPoolAddressesProvider provider)
    public
    view
    override
    returns (address[] memory)
  {
    ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
    return lendingPool.getReservesList();
  }

  function getSimpleReservesData(ILendingPoolAddressesProvider provider)
    public
    view
    override
    returns (
      AggregatedReserveData[] memory,
      uint256,
      uint256
    )
  {
    ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
    address[] memory reserves = lendingPool.getReservesList();
    AggregatedReserveData[] memory reservesData = new AggregatedReserveData[](reserves.length);

    for (uint256 i = 0; i < reserves.length; i++) {
      AggregatedReserveData memory reserveData = reservesData[i];
      reserveData.underlyingAsset = reserves[i];

      // reserve current state
      DataTypes.ReserveData memory baseData = lendingPool.getReserveData(
        reserveData.underlyingAsset
      );
      reserveData.liquidityIndex = baseData.liquidityIndex;
      reserveData.variableBorrowIndex = baseData.variableBorrowIndex;
      reserveData.liquidityRate = baseData.currentLiquidityRate;
      reserveData.variableBorrowRate = baseData.currentVariableBorrowRate;
      reserveData.stableBorrowRate = baseData.currentStableBorrowRate;
      reserveData.lastUpdateTimestamp = baseData.lastUpdateTimestamp;
      reserveData.viTokenAddress = baseData.viTokenAddress;
      reserveData.stableVdTokenAddress = baseData.stableVdTokenAddress;
      reserveData.variableVdTokenAddress = baseData.variableVdTokenAddress;
      reserveData.interestRateStrategyAddress = baseData.interestRateStrategyAddress;
      reserveData.priceInEth = oracle.getAssetPrice(reserveData.underlyingAsset);

      reserveData.availableLiquidity = IERC20Detailed(reserveData.underlyingAsset).balanceOf(
        reserveData.viTokenAddress
      );
      (
        reserveData.totalPrincipalStableDebt,
        ,
        reserveData.averageStableRate,
        reserveData.stableDebtLastUpdateTimestamp
      ) = IStableVdToken(reserveData.stableVdTokenAddress).getSupplyData();
      reserveData.totalScaledVariableDebt = IVariableVdToken(reserveData.variableVdTokenAddress)
        .scaledTotalSupply();

      // reserve configuration

      // we're getting this info from the viToken, because some of assets can be not compliant with ETC20Detailed
      reserveData.symbol = IERC20Detailed(reserveData.underlyingAsset).symbol();
      reserveData.name = '';

      (
        reserveData.baseLTVasCollateral,
        reserveData.reserveLiquidationThreshold,
        reserveData.reserveLiquidationBonus,
        reserveData.decimals,
        reserveData.reserveFactor
      ) = baseData.configuration.getParamsMemory();
      (
        reserveData.isActive,
        reserveData.isFrozen,
        reserveData.borrowingEnabled,
        reserveData.stableBorrowRateEnabled
      ) = baseData.configuration.getFlagsMemory();
      reserveData.usageAsCollateralEnabled = reserveData.baseLTVasCollateral != 0;
      (
        reserveData.variableRateSlope1,
        reserveData.variableRateSlope2,
        reserveData.stableRateSlope1,
        reserveData.stableRateSlope2
      ) = getInterestRateStrategySlopes(
        DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress)
      );

      // incentives
      if (address(0) != address(incentivesController)) {
        (
          reserveData.viTokenIncentivesIndex,
          reserveData.aEmissionPerSecond,
          reserveData.aIncentivesLastUpdateTimestamp
        ) = incentivesController.getAssetData(reserveData.viTokenAddress);

        (
          reserveData.sTokenIncentivesIndex,
          reserveData.sEmissionPerSecond,
          reserveData.sIncentivesLastUpdateTimestamp
        ) = incentivesController.getAssetData(reserveData.stableVdTokenAddress);

        (
          reserveData.vTokenIncentivesIndex,
          reserveData.vEmissionPerSecond,
          reserveData.vIncentivesLastUpdateTimestamp
        ) = incentivesController.getAssetData(reserveData.variableVdTokenAddress);
      }
    }

    uint256 emissionEndTimestamp;
    if (address(0) != address(incentivesController)) {
      emissionEndTimestamp = incentivesController.DISTRIBUTION_END();
    }

    return (reservesData, oracle.getAssetPrice(MOCK_USD_ADDRESS), emissionEndTimestamp);
  }

  function getUserReservesData(ILendingPoolAddressesProvider provider, address user)
    external
    view
    override
    returns (UserReserveData[] memory, uint256)
  {
    ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
    address[] memory reserves = lendingPool.getReservesList();
    DataTypes.UserConfigurationMap memory userConfig = lendingPool.getUserConfiguration(user);

    UserReserveData[] memory userReservesData = new UserReserveData[](
      user != address(0) ? reserves.length : 0
    );

    for (uint256 i = 0; i < reserves.length; i++) {
      DataTypes.ReserveData memory baseData = lendingPool.getReserveData(reserves[i]);
      // incentives
      if (address(0) != address(incentivesController)) {
        userReservesData[i].viTokenincentivesUserIndex = incentivesController.getUserAssetData(
          user,
          baseData.viTokenAddress
        );
        userReservesData[i].vTokenincentivesUserIndex = incentivesController.getUserAssetData(
          user,
          baseData.variableVdTokenAddress
        );
        userReservesData[i].sTokenincentivesUserIndex = incentivesController.getUserAssetData(
          user,
          baseData.stableVdTokenAddress
        );
      }
      // user reserve data
      userReservesData[i].underlyingAsset = reserves[i];
      userReservesData[i].scaledViTokenBalance = IViToken(baseData.viTokenAddress).scaledBalanceOf(
        user
      );
      userReservesData[i].usageAsCollateralEnabledOnUser = userConfig.isUsingAsCollateral(i);

      if (userConfig.isBorrowing(i)) {
        userReservesData[i].scaledVariableDebt = IVariableVdToken(baseData.variableVdTokenAddress)
          .scaledBalanceOf(user);
        userReservesData[i].principalStableDebt = IStableVdToken(baseData.stableVdTokenAddress)
          .principalBalanceOf(user);
        if (userReservesData[i].principalStableDebt != 0) {
          userReservesData[i].stableBorrowRate = IStableVdToken(baseData.stableVdTokenAddress)
            .getUserStableRate(user);
          userReservesData[i].stableBorrowLastUpdateTimestamp = IStableVdToken(
            baseData.stableVdTokenAddress
          ).getUserLastUpdated(user);
        }
      }
    }

    uint256 userUnclaimedRewards;
    if (address(0) != address(incentivesController)) {
      userUnclaimedRewards = incentivesController.getUserUnclaimedRewards(user);
    }

    return (userReservesData, userUnclaimedRewards);
  }

  function getReservesData(ILendingPoolAddressesProvider provider, address user)
    external
    view
    override
    returns (
      AggregatedReserveData[] memory,
      UserReserveData[] memory,
      uint256,
      IncentivesControllerData memory
    )
  {
    ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
    address[] memory reserves = lendingPool.getReservesList();
    DataTypes.UserConfigurationMap memory userConfig = lendingPool.getUserConfiguration(user);

    AggregatedReserveData[] memory reservesData = new AggregatedReserveData[](reserves.length);
    UserReserveData[] memory userReservesData = new UserReserveData[](
      user != address(0) ? reserves.length : 0
    );

    for (uint256 i = 0; i < reserves.length; i++) {
      AggregatedReserveData memory reserveData = reservesData[i];
      reserveData.underlyingAsset = reserves[i];

      // reserve current state
      DataTypes.ReserveData memory baseData = lendingPool.getReserveData(
        reserveData.underlyingAsset
      );
      reserveData.liquidityIndex = baseData.liquidityIndex;
      reserveData.variableBorrowIndex = baseData.variableBorrowIndex;
      reserveData.liquidityRate = baseData.currentLiquidityRate;
      reserveData.variableBorrowRate = baseData.currentVariableBorrowRate;
      reserveData.stableBorrowRate = baseData.currentStableBorrowRate;
      reserveData.lastUpdateTimestamp = baseData.lastUpdateTimestamp;
      reserveData.viTokenAddress = baseData.viTokenAddress;
      reserveData.stableVdTokenAddress = baseData.stableVdTokenAddress;
      reserveData.variableVdTokenAddress = baseData.variableVdTokenAddress;
      reserveData.interestRateStrategyAddress = baseData.interestRateStrategyAddress;
      reserveData.priceInEth = oracle.getAssetPrice(reserveData.underlyingAsset);

      reserveData.availableLiquidity = IERC20Detailed(reserveData.underlyingAsset).balanceOf(
        reserveData.viTokenAddress
      );
      (
        reserveData.totalPrincipalStableDebt,
        ,
        reserveData.averageStableRate,
        reserveData.stableDebtLastUpdateTimestamp
      ) = IStableVdToken(reserveData.stableVdTokenAddress).getSupplyData();
      reserveData.totalScaledVariableDebt = IVariableVdToken(reserveData.variableVdTokenAddress)
        .scaledTotalSupply();

      // reserve configuration

      // we're getting this info from the viToken, because some of assets can be not compliant with ETC20Detailed
      reserveData.symbol = IERC20Detailed(reserveData.underlyingAsset).symbol();
      reserveData.name = '';

      (
        reserveData.baseLTVasCollateral,
        reserveData.reserveLiquidationThreshold,
        reserveData.reserveLiquidationBonus,
        reserveData.decimals,
        reserveData.reserveFactor
      ) = baseData.configuration.getParamsMemory();
      (
        reserveData.isActive,
        reserveData.isFrozen,
        reserveData.borrowingEnabled,
        reserveData.stableBorrowRateEnabled
      ) = baseData.configuration.getFlagsMemory();
      reserveData.usageAsCollateralEnabled = reserveData.baseLTVasCollateral != 0;
      (
        reserveData.variableRateSlope1,
        reserveData.variableRateSlope2,
        reserveData.stableRateSlope1,
        reserveData.stableRateSlope2
      ) = getInterestRateStrategySlopes(
        DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress)
      );

      // incentives
      if (address(0) != address(incentivesController)) {
        (
          reserveData.viTokenIncentivesIndex,
          reserveData.aEmissionPerSecond,
          reserveData.aIncentivesLastUpdateTimestamp
        ) = incentivesController.getAssetData(reserveData.viTokenAddress);

        (
          reserveData.sTokenIncentivesIndex,
          reserveData.sEmissionPerSecond,
          reserveData.sIncentivesLastUpdateTimestamp
        ) = incentivesController.getAssetData(reserveData.stableVdTokenAddress);

        (
          reserveData.vTokenIncentivesIndex,
          reserveData.vEmissionPerSecond,
          reserveData.vIncentivesLastUpdateTimestamp
        ) = incentivesController.getAssetData(reserveData.variableVdTokenAddress);
      }

      if (user != address(0)) {
        // incentives
        if (address(0) != address(incentivesController)) {
          userReservesData[i].viTokenincentivesUserIndex = incentivesController.getUserAssetData(
            user,
            reserveData.viTokenAddress
          );
          userReservesData[i].vTokenincentivesUserIndex = incentivesController.getUserAssetData(
            user,
            reserveData.variableVdTokenAddress
          );
          userReservesData[i].sTokenincentivesUserIndex = incentivesController.getUserAssetData(
            user,
            reserveData.stableVdTokenAddress
          );
        }
        // user reserve data
        userReservesData[i].underlyingAsset = reserveData.underlyingAsset;
        userReservesData[i].scaledViTokenBalance = IViToken(reserveData.viTokenAddress)
          .scaledBalanceOf(user);
        userReservesData[i].usageAsCollateralEnabledOnUser = userConfig.isUsingAsCollateral(i);

        if (userConfig.isBorrowing(i)) {
          userReservesData[i].scaledVariableDebt = IVariableVdToken(
            reserveData.variableVdTokenAddress
          ).scaledBalanceOf(user);
          userReservesData[i].principalStableDebt = IStableVdToken(reserveData.stableVdTokenAddress)
            .principalBalanceOf(user);
          if (userReservesData[i].principalStableDebt != 0) {
            userReservesData[i].stableBorrowRate = IStableVdToken(reserveData.stableVdTokenAddress)
              .getUserStableRate(user);
            userReservesData[i].stableBorrowLastUpdateTimestamp = IStableVdToken(
              reserveData.stableVdTokenAddress
            ).getUserLastUpdated(user);
          }
        }
      }
    }

    IncentivesControllerData memory incentivesControllerData;

    if (address(0) != address(incentivesController)) {
      if (user != address(0)) {
        incentivesControllerData.userUnclaimedRewards = incentivesController
          .getUserUnclaimedRewards(user);
      }
      incentivesControllerData.emissionEndTimestamp = incentivesController.DISTRIBUTION_END();
    }

    return (
      reservesData,
      userReservesData,
      oracle.getAssetPrice(MOCK_USD_ADDRESS),
      incentivesControllerData
    );
  }
}