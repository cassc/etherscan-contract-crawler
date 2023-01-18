// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IPoolConfigurator, IAaveOracle, ConfiguratorInputTypes} from 'aave-address-book/AaveV3.sol';
import {IERC20} from '../interfaces/IERC20.sol';
import {IChainlinkAggregator} from '../interfaces/IChainlinkAggregator.sol';
import {IGenericV3ListingEngine} from './IGenericV3ListingEngine.sol';

/**
 * @dev Helper smart contract implementing a generalized Aave v3 listing flow for a set of assets
 * It is planned to be used via delegatecall, by any contract having appropriate permissions to
 * do a listing, or any other granular config
 * Assumptions:
 * - Only one a/v/s token implementation for all assets
 * - Only one RewardsController for all assets
 * - Only one Collector for all assets
 * @author BGD Labs
 */
contract GenericV3ListingEngine is IGenericV3ListingEngine {
  IPoolConfigurator public immutable POOL_CONFIGURATOR;
  IAaveOracle public immutable ORACLE;
  address public immutable ATOKEN_IMPL;
  address public immutable VTOKEN_IMPL;
  address public immutable STOKEN_IMPL;
  address public immutable REWARDS_CONTROLLER;
  address public immutable COLLECTOR;

  constructor(
    IPoolConfigurator configurator,
    IAaveOracle oracle,
    address aTokenImpl,
    address vTokenImpl,
    address sTokenImpl,
    address rewardsController,
    address collector
  ) {
    require(address(configurator) != address(0), 'ONLY_NONZERO_CONFIGURATOR');
    require(address(oracle) != address(0), 'ONLY_NONZERO_ORACLE');
    require(aTokenImpl != address(0), 'ONLY_NONZERO_ATOKEN');
    require(vTokenImpl != address(0), 'ONLY_NONZERO_VTOKEN');
    require(sTokenImpl != address(0), 'ONLY_NONZERO_STOKEN');
    require(rewardsController != address(0), 'ONLY_NONZERO_REWARDS_CONTROLLER');
    require(collector != address(0), 'ONLY_NONZERO_COLLECTOR');

    POOL_CONFIGURATOR = IPoolConfigurator(configurator);
    ORACLE = IAaveOracle(oracle);
    ATOKEN_IMPL = aTokenImpl;
    VTOKEN_IMPL = vTokenImpl;
    STOKEN_IMPL = sTokenImpl;
    REWARDS_CONTROLLER = rewardsController;
    COLLECTOR = collector;
  }

  /// @inheritdoc IGenericV3ListingEngine
  function listAssets(PoolContext memory context, Listing[] memory listings) public {
    require(listings.length != 0, 'AT_LEAST_ONE_ASSET_REQUIRED');

    AssetsConfig memory configs = _repackListing(listings);

    _setPriceFeeds(configs.ids, configs.basics);

    _initAssets(context, configs.ids, configs.basics);

    _configureCaps(configs.ids, configs.caps);

    _configBorrowSide(configs.ids, configs.borrows);

    _configCollateralSide(configs.ids, configs.collaterals);
  }

  function _setPriceFeeds(address[] memory ids, Basic[] memory basics) internal {
    address[] memory assets = new address[](ids.length);
    address[] memory sources = new address[](ids.length);

    for (uint256 i = 0; i < ids.length; i++) {
      require(basics[i].priceFeed != address(0), 'PRICE_FEED_ALWAYS_REQUIRED');
      require(
        IChainlinkAggregator(basics[i].priceFeed).latestAnswer() > 0,
        'FEED_SHOULD_RETURN_POSITIVE_PRICE'
      );
      assets[i] = ids[i];
      sources[i] = basics[i].priceFeed;
    }

    ORACLE.setAssetSources(assets, sources);
  }

  /// @dev mandatory configurations for any asset getting listed, including oracle config and basic init
  function _initAssets(
    PoolContext memory context,
    address[] memory ids,
    Basic[] memory basics
  ) internal {
    ConfiguratorInputTypes.InitReserveInput[]
      memory initReserveInputs = new ConfiguratorInputTypes.InitReserveInput[](ids.length);
    for (uint256 i = 0; i < ids.length; i++) {
      uint8 decimals = IERC20(ids[i]).decimals();
      require(decimals > 0, 'INVALID_ASSET_DECIMALS');
      require(basics[i].rateStrategy != address(0), 'ONLY_NONZERO_RATE_STRATEGY');

      initReserveInputs[i] = ConfiguratorInputTypes.InitReserveInput({
        aTokenImpl: ATOKEN_IMPL,
        stableDebtTokenImpl: STOKEN_IMPL,
        variableDebtTokenImpl: VTOKEN_IMPL,
        underlyingAssetDecimals: decimals,
        interestRateStrategyAddress: basics[i].rateStrategy,
        underlyingAsset: ids[i],
        treasury: COLLECTOR,
        incentivesController: REWARDS_CONTROLLER,
        aTokenName: string.concat('Aave ', context.networkName, ' ', basics[i].assetSymbol),
        aTokenSymbol: string.concat('a', context.networkAbbreviation, basics[i].assetSymbol),
        variableDebtTokenName: string.concat(
          'Aave ',
          context.networkName,
          ' Variable Debt ',
          basics[i].assetSymbol
        ),
        variableDebtTokenSymbol: string.concat(
          'variableDebt',
          context.networkAbbreviation,
          basics[i].assetSymbol
        ),
        stableDebtTokenName: string.concat(
          'Aave ',
          context.networkName,
          ' Stable Debt ',
          basics[i].assetSymbol
        ),
        stableDebtTokenSymbol: string.concat(
          'stableDebt',
          context.networkAbbreviation,
          basics[i].assetSymbol
        ),
        params: bytes('')
      });
    }
    POOL_CONFIGURATOR.initReserves(initReserveInputs);
  }

  function _configureCaps(address[] memory ids, Caps[] memory caps) internal {
    for (uint256 i = 0; i < ids.length; i++) {
      if (caps[i].supplyCap != 0) {
        POOL_CONFIGURATOR.setSupplyCap(ids[i], caps[i].supplyCap);
      }

      if (caps[i].borrowCap != 0) {
        POOL_CONFIGURATOR.setBorrowCap(ids[i], caps[i].borrowCap);
      }
    }
  }

  function _configBorrowSide(address[] memory ids, Borrow[] memory borrows) internal {
    for (uint256 i = 0; i < ids.length; i++) {
      if (borrows[i].enabledToBorrow) {
        POOL_CONFIGURATOR.setReserveBorrowing(ids[i], true);

        // If enabled to borrow, the reserve factor should always be configured and > 0
        require(
          borrows[i].reserveFactor > 0 && borrows[i].reserveFactor < 100_00,
          'INVALID_RESERVE_FACTOR'
        );
        POOL_CONFIGURATOR.setReserveFactor(ids[i], borrows[i].reserveFactor);

        if (borrows[i].stableRateModeEnabled) {
          POOL_CONFIGURATOR.setReserveStableRateBorrowing(ids[i], true);
        }

        if (borrows[i].borrowableInIsolation) {
          POOL_CONFIGURATOR.setBorrowableInIsolation(ids[i], true);
        }

        if (borrows[i].withSiloedBorrowing) {
          POOL_CONFIGURATOR.setSiloedBorrowing(ids[i], true);
        }
      }

      if (borrows[i].flashloanable) {
        POOL_CONFIGURATOR.setReserveFlashLoaning(ids[i], true);
      }
    }
  }

  function _configCollateralSide(address[] memory ids, Collateral[] memory collaterals) internal {
    for (uint256 i = 0; i < ids.length; i++) {
      if (collaterals[i].liqThreshold != 0) {
        require(
          collaterals[i].liqThreshold + collaterals[i].liqBonus < 100_00,
          'INVALID_LIQ_PARAMS_ABOVE_100'
        );
        require(collaterals[i].liqProtocolFee < 100_00, 'INVALID_LIQ_PROTOCOL_FEE');

        POOL_CONFIGURATOR.configureReserveAsCollateral(
          ids[i],
          collaterals[i].ltv,
          collaterals[i].liqThreshold,
          // For reference, this is to simplify the interaction with the Aave protocol,
          // as there the definition is as e.g. 105% (5% bonus for liquidators)
          100_00 + collaterals[i].liqBonus
        );

        POOL_CONFIGURATOR.setLiquidationProtocolFee(ids[i], collaterals[i].liqProtocolFee);

        if (collaterals[i].debtCeiling != 0) {
          POOL_CONFIGURATOR.setDebtCeiling(ids[i], collaterals[i].debtCeiling);
        }
      }

      if (collaterals[i].eModeCategory != 0) {
        POOL_CONFIGURATOR.setAssetEModeCategory(ids[i], collaterals[i].eModeCategory);
      }
    }
  }

  function _repackListing(Listing[] memory listings) internal pure returns (AssetsConfig memory) {
    address[] memory ids = new address[](listings.length);
    Basic[] memory basics = new Basic[](listings.length);
    Borrow[] memory borrows = new Borrow[](listings.length);
    Collateral[] memory collaterals = new Collateral[](listings.length);
    Caps[] memory caps = new Caps[](listings.length);

    for (uint256 i = 0; i < listings.length; i++) {
      require(listings[i].asset != address(0), 'INVALID_ASSET');
      ids[i] = listings[i].asset;
      basics[i] = Basic({
        assetSymbol: listings[i].assetSymbol,
        priceFeed: listings[i].priceFeed,
        rateStrategy: listings[i].rateStrategy
      });
      borrows[i] = Borrow({
        enabledToBorrow: listings[i].enabledToBorrow,
        flashloanable: listings[i].flashloanable,
        stableRateModeEnabled: listings[i].stableRateModeEnabled,
        borrowableInIsolation: listings[i].borrowableInIsolation,
        withSiloedBorrowing: listings[i].withSiloedBorrowing,
        reserveFactor: listings[i].reserveFactor
      });
      collaterals[i] = Collateral({
        ltv: listings[i].ltv,
        liqThreshold: listings[i].liqThreshold,
        liqBonus: listings[i].liqBonus,
        debtCeiling: listings[i].debtCeiling,
        liqProtocolFee: listings[i].liqProtocolFee,
        eModeCategory: listings[i].eModeCategory
      });
      caps[i] = Caps({supplyCap: listings[i].supplyCap, borrowCap: listings[i].borrowCap});
    }

    return
      AssetsConfig({
        ids: ids,
        basics: basics,
        borrows: borrows,
        collaterals: collaterals,
        caps: caps
      });
  }
}