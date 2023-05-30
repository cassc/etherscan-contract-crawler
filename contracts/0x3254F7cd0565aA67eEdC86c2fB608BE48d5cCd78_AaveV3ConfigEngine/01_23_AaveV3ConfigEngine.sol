// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ConfiguratorInputTypes, DataTypes} from 'aave-address-book/AaveV3.sol';
import {ReserveConfiguration} from 'aave-v3-core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {PercentageMath} from 'aave-v3-core/contracts/protocol/libraries/math/PercentageMath.sol';
import {IERC20Metadata} from 'solidity-utils/contracts/oz-common/interfaces/IERC20Metadata.sol';
import {IChainlinkAggregator} from '../interfaces/IChainlinkAggregator.sol';
import {EngineFlags} from './EngineFlags.sol';
import './IAaveV3ConfigEngine.sol';

/**
 * @dev Helper smart contract abstracting the complexity of changing configurations on Aave v3, simplifying
 * listing flow and parameters updates.
 * - It is planned to be used via delegatecall, by any contract having appropriate permissions to
 * do a listing, or any other granular config
 * Assumptions:
 * - Only one a/v/s token implementation for all assets
 * - Only one RewardsController for all assets
 * - Only one Collector for all assets
 * @author BGD Labs
 */
contract AaveV3ConfigEngine is IAaveV3ConfigEngine {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using PercentageMath for uint256;

  struct AssetsConfig {
    address[] ids;
    Basic[] basics;
    Borrow[] borrows;
    Collateral[] collaterals;
    Caps[] caps;
    IV3RateStrategyFactory.RateStrategyParams[] rates;
  }

  struct Basic {
    string assetSymbol;
    address priceFeed;
    IV3RateStrategyFactory.RateStrategyParams rateStrategyParams;
    TokenImplementations implementations;
  }

  struct Borrow {
    uint256 enabledToBorrow; // Main config flag, if EngineFlag.DISABLED, some of the other fields will not be considered
    uint256 flashloanable; // EngineFlag.ENABLED for true, EngineFlag.DISABLED for false otherwise EngineFlag.KEEP_CURRENT
    uint256 stableRateModeEnabled; // EngineFlag.ENABLED for true, EngineFlag.DISABLED for false otherwise EngineFlag.KEEP_CURRENT
    uint256 borrowableInIsolation; // EngineFlag.ENABLED for true, EngineFlag.DISABLED for false otherwise EngineFlag.KEEP_CURRENT
    uint256 withSiloedBorrowing; // EngineFlag.ENABLED for true, EngineFlag.DISABLED for false otherwise EngineFlag.KEEP_CURRENT
    uint256 reserveFactor; // With 2 digits precision, `10_00` for 10%. Should be positive and < 100_00
  }

  struct Collateral {
    uint256 ltv; // Only considered if liqThreshold > 0. With 2 digits precision, `10_00` for 10%. Should be lower than liquidationThreshold
    uint256 liqThreshold; // If `0`, the asset will not be enabled as collateral. Same format as ltv, and should be higher
    uint256 liqBonus; // Only considered if liqThreshold > 0. Same format as ltv
    uint256 debtCeiling; // Only considered if liqThreshold > 0. In USD and without decimals, so 100_000 for 100k USD debt ceiling
    uint256 liqProtocolFee; // Only considered if liqThreshold > 0. Same format as ltv
    uint256 eModeCategory;
  }

  struct Caps {
    uint256 supplyCap; // Always configured. In "big units" of the asset, and no decimals. 100 for 100 ETH supply cap
    uint256 borrowCap; // Always configured, no matter if enabled for borrowing or not. Same format as supply cap
  }

  IPool public immutable POOL;
  IPoolConfigurator public immutable POOL_CONFIGURATOR;
  IAaveOracle public immutable ORACLE;
  address public immutable ATOKEN_IMPL;
  address public immutable VTOKEN_IMPL;
  address public immutable STOKEN_IMPL;
  address public immutable REWARDS_CONTROLLER;
  address public immutable COLLECTOR;
  IV3RateStrategyFactory public immutable RATE_STRATEGIES_FACTORY;

  constructor(
    IPool pool,
    IPoolConfigurator configurator,
    IAaveOracle oracle,
    address aTokenImpl,
    address vTokenImpl,
    address sTokenImpl,
    address rewardsController,
    address collector,
    IV3RateStrategyFactory rateStrategiesFactory
  ) {
    require(address(pool) != address(0), 'ONLY_NONZERO_POOL');
    require(address(configurator) != address(0), 'ONLY_NONZERO_CONFIGURATOR');
    require(address(oracle) != address(0), 'ONLY_NONZERO_ORACLE');
    require(aTokenImpl != address(0), 'ONLY_NONZERO_ATOKEN');
    require(vTokenImpl != address(0), 'ONLY_NONZERO_VTOKEN');
    require(sTokenImpl != address(0), 'ONLY_NONZERO_STOKEN');
    require(rewardsController != address(0), 'ONLY_NONZERO_REWARDS_CONTROLLER');
    require(collector != address(0), 'ONLY_NONZERO_COLLECTOR');
    require(address(rateStrategiesFactory) != address(0), 'ONLY_NONZERO_RATES_FACTORY');

    POOL = pool;
    POOL_CONFIGURATOR = configurator;
    ORACLE = oracle;
    ATOKEN_IMPL = aTokenImpl;
    VTOKEN_IMPL = vTokenImpl;
    STOKEN_IMPL = sTokenImpl;
    REWARDS_CONTROLLER = rewardsController;
    COLLECTOR = collector;
    RATE_STRATEGIES_FACTORY = rateStrategiesFactory;
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function listAssets(PoolContext memory context, Listing[] memory listings) public {
    require(listings.length != 0, 'AT_LEAST_ONE_ASSET_REQUIRED');

    ListingWithCustomImpl[] memory customListings = new ListingWithCustomImpl[](listings.length);
    for (uint256 i = 0; i < listings.length; i++) {
      customListings[i] = ListingWithCustomImpl({
        base: listings[i],
        implementations: TokenImplementations({
          aToken: ATOKEN_IMPL,
          vToken: VTOKEN_IMPL,
          sToken: STOKEN_IMPL
        })
      });
    }

    listAssetsCustom(context, customListings);
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function listAssetsCustom(
    PoolContext memory context,
    ListingWithCustomImpl[] memory listings
  ) public {
    require(listings.length != 0, 'AT_LEAST_ONE_ASSET_REQUIRED');

    AssetsConfig memory configs = _repackListing(listings);

    _setPriceFeeds(configs.ids, configs.basics);

    _initAssets(context, configs.ids, configs.basics, configs.rates);

    _configureCaps(configs.ids, configs.caps);

    _configBorrowSide(configs.ids, configs.borrows);

    _configCollateralSide(configs.ids, configs.collaterals);
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateCaps(CapsUpdate[] memory updates) public {
    require(updates.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    AssetsConfig memory configs = _repackCapsUpdate(updates);

    _configureCaps(configs.ids, configs.caps);
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updatePriceFeeds(PriceFeedUpdate[] memory updates) public {
    require(updates.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    AssetsConfig memory configs = _repackPriceFeed(updates);

    _setPriceFeeds(configs.ids, configs.basics);
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateCollateralSide(CollateralUpdate[] memory updates) public {
    require(updates.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    AssetsConfig memory configs = _repackCollateralUpdate(updates);

    _configCollateralSide(configs.ids, configs.collaterals);
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateBorrowSide(BorrowUpdate[] memory updates) public {
    require(updates.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    AssetsConfig memory configs = _repackBorrowUpdate(updates);

    _configBorrowSide(configs.ids, configs.borrows);
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateRateStrategies(RateStrategyUpdate[] memory updates) public {
    require(updates.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    AssetsConfig memory configs = _repackRatesUpdate(updates);

    _configRateStrategies(configs.ids, configs.rates);
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
    PoolContext memory,
    address[] memory ids,
    Basic[] memory basics,
    IV3RateStrategyFactory.RateStrategyParams[] memory rates
  ) internal {
    ConfiguratorInputTypes.InitReserveInput[]
      memory initReserveInputs = new ConfiguratorInputTypes.InitReserveInput[](ids.length);
    address[] memory strategies = RATE_STRATEGIES_FACTORY.createStrategies(rates);

    for (uint256 i = 0; i < ids.length; i++) {
      uint8 decimals = IERC20Metadata(ids[i]).decimals();
      require(decimals > 0, 'INVALID_ASSET_DECIMALS');

      initReserveInputs[i] = ConfiguratorInputTypes.InitReserveInput({
        aTokenImpl: basics[i].implementations.aToken,
        stableDebtTokenImpl: basics[i].implementations.sToken,
        variableDebtTokenImpl: basics[i].implementations.vToken,
        underlyingAssetDecimals: decimals,
        interestRateStrategyAddress: strategies[i],
        underlyingAsset: ids[i],
        treasury: COLLECTOR,
        incentivesController: REWARDS_CONTROLLER,
        aTokenName: string(string.concat('Spark ', bytes(basics[i].assetSymbol))),
        aTokenSymbol: string(string.concat('sp', bytes(basics[i].assetSymbol))),
        variableDebtTokenName: string(string.concat(
          'Spark Variable Debt ',
          bytes(basics[i].assetSymbol)
        )),
        variableDebtTokenSymbol: string(string.concat(
          'variableDebt',
          bytes(basics[i].assetSymbol)
        )),
        stableDebtTokenName: string(string.concat(
          'Spark Stable Debt ',
          bytes(basics[i].assetSymbol)
        )),
        stableDebtTokenSymbol: string(string.concat(
          'stableDebt',
          bytes(basics[i].assetSymbol)
        )),
        params: bytes('')
      });
    }
    POOL_CONFIGURATOR.initReserves(initReserveInputs);
  }

  function _configureCaps(address[] memory ids, Caps[] memory caps) internal {
    for (uint256 i = 0; i < ids.length; i++) {
      if (caps[i].supplyCap != EngineFlags.KEEP_CURRENT) {
        POOL_CONFIGURATOR.setSupplyCap(ids[i], caps[i].supplyCap);
      }

      if (caps[i].borrowCap != EngineFlags.KEEP_CURRENT) {
        POOL_CONFIGURATOR.setBorrowCap(ids[i], caps[i].borrowCap);
      }
    }
  }

  function _configBorrowSide(address[] memory ids, Borrow[] memory borrows) internal {
    for (uint256 i = 0; i < ids.length; i++) {
      if (borrows[i].enabledToBorrow != EngineFlags.KEEP_CURRENT) {
        POOL_CONFIGURATOR.setReserveBorrowing(
          ids[i],
          EngineFlags.toBool(borrows[i].enabledToBorrow)
        );
      } else {
        (, , bool borrowingEnabled, , ) = POOL.getConfiguration(ids[i]).getFlags();
        borrows[i].enabledToBorrow = EngineFlags.fromBool(borrowingEnabled);
      }

      if (borrows[i].enabledToBorrow == EngineFlags.ENABLED) {
        if (borrows[i].stableRateModeEnabled != EngineFlags.KEEP_CURRENT) {
          POOL_CONFIGURATOR.setReserveStableRateBorrowing(
            ids[i],
            EngineFlags.toBool(borrows[i].stableRateModeEnabled)
          );
        }
      }

      if (borrows[i].borrowableInIsolation != EngineFlags.KEEP_CURRENT) {
        POOL_CONFIGURATOR.setBorrowableInIsolation(
          ids[i],
          EngineFlags.toBool(borrows[i].borrowableInIsolation)
        );
      }

      if (borrows[i].withSiloedBorrowing != EngineFlags.KEEP_CURRENT) {
        POOL_CONFIGURATOR.setSiloedBorrowing(
          ids[i],
          EngineFlags.toBool(borrows[i].withSiloedBorrowing)
        );
      }

      // TODO: update once all the underlying v3 instances are in 3.0.1 (supporting 100% RF)
      // The reserve factor should always be > 0
      require(
        (borrows[i].reserveFactor > 0 && borrows[i].reserveFactor < 100_00) ||
          borrows[i].reserveFactor == EngineFlags.KEEP_CURRENT,
        'INVALID_RESERVE_FACTOR'
      );

      if (borrows[i].reserveFactor != EngineFlags.KEEP_CURRENT) {
        POOL_CONFIGURATOR.setReserveFactor(ids[i], borrows[i].reserveFactor);
      }

      // TODO: update once all the underlying v3 instances are in 3.0.1 (supporting setReserveFlashLoaning())
      if (borrows[i].flashloanable == EngineFlags.ENABLED) {
        POOL_CONFIGURATOR.setReserveFlashLoaning(ids[i], true);
      }
    }
  }

  function _configRateStrategies(
    address[] memory ids,
    IV3RateStrategyFactory.RateStrategyParams[] memory strategiesParams
  ) internal {
    for (uint256 i = 0; i < strategiesParams.length; i++) {
      if (
        strategiesParams[i].variableRateSlope1 == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].variableRateSlope2 == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].optimalUsageRatio == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].baseVariableBorrowRate == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].stableRateSlope1 == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].stableRateSlope2 == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].baseStableRateOffset == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].stableRateExcessOffset == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].optimalStableToTotalDebtRatio == EngineFlags.KEEP_CURRENT
      ) {
        IV3RateStrategyFactory.RateStrategyParams
          memory currentStrategyData = RATE_STRATEGIES_FACTORY.getStrategyDataOfAsset(ids[i]);

        if (strategiesParams[i].variableRateSlope1 == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].variableRateSlope1 = currentStrategyData.variableRateSlope1;
        }

        if (strategiesParams[i].variableRateSlope2 == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].variableRateSlope2 = currentStrategyData.variableRateSlope2;
        }

        if (strategiesParams[i].optimalUsageRatio == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].optimalUsageRatio = currentStrategyData.optimalUsageRatio;
        }

        if (strategiesParams[i].baseVariableBorrowRate == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].baseVariableBorrowRate = currentStrategyData.baseVariableBorrowRate;
        }

        if (strategiesParams[i].stableRateSlope1 == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].stableRateSlope1 = currentStrategyData.stableRateSlope1;
        }

        if (strategiesParams[i].stableRateSlope2 == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].stableRateSlope2 = currentStrategyData.stableRateSlope2;
        }

        if (strategiesParams[i].baseStableRateOffset == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].baseStableRateOffset = currentStrategyData.baseStableRateOffset;
        }

        if (strategiesParams[i].stableRateExcessOffset == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].stableRateExcessOffset = currentStrategyData.stableRateExcessOffset;
        }

        if (strategiesParams[i].optimalStableToTotalDebtRatio == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].optimalStableToTotalDebtRatio = currentStrategyData
            .optimalStableToTotalDebtRatio;
        }
      }
    }

    address[] memory strategies = RATE_STRATEGIES_FACTORY.createStrategies(strategiesParams);

    for (uint256 i = 0; i < strategies.length; i++) {
      POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(ids[i], strategies[i]);
    }
  }

  function _configCollateralSide(address[] memory ids, Collateral[] memory collaterals) internal {
    for (uint256 i = 0; i < ids.length; i++) {
      if (collaterals[i].liqThreshold != 0) {
        bool notAllKeepCurrent = collaterals[i].ltv != EngineFlags.KEEP_CURRENT ||
          collaterals[i].liqThreshold != EngineFlags.KEEP_CURRENT ||
          collaterals[i].liqBonus != EngineFlags.KEEP_CURRENT;

        bool atLeastOneKeepCurrent = collaterals[i].ltv == EngineFlags.KEEP_CURRENT ||
          collaterals[i].liqThreshold == EngineFlags.KEEP_CURRENT ||
          collaterals[i].liqBonus == EngineFlags.KEEP_CURRENT;

        if (notAllKeepCurrent && atLeastOneKeepCurrent) {
          DataTypes.ReserveConfigurationMap memory configuration = POOL.getConfiguration(ids[i]);
          (
            uint256 currentLtv,
            uint256 currentLiqThreshold,
            uint256 currentLiqBonus,
            ,
            ,

          ) = configuration.getParams();

          if (collaterals[i].ltv == EngineFlags.KEEP_CURRENT) {
            collaterals[i].ltv = currentLtv;
          }

          if (collaterals[i].liqThreshold == EngineFlags.KEEP_CURRENT) {
            collaterals[i].liqThreshold = currentLiqThreshold;
          }

          if (collaterals[i].liqBonus == EngineFlags.KEEP_CURRENT) {
            // Subtracting 100_00 to be consistent with the engine as 100_00 gets added while setting the liqBonus
            collaterals[i].liqBonus = currentLiqBonus - 100_00;
          }
        }

        if (notAllKeepCurrent) {
          // LT*LB (in %) should never be above 100%, because it means instant undercollateralization
          require(
            collaterals[i].liqThreshold.percentMul(100_00 + collaterals[i].liqBonus) <= 100_00,
            'INVALID_LT_LB_RATIO'
          );

          POOL_CONFIGURATOR.configureReserveAsCollateral(
            ids[i],
            collaterals[i].ltv,
            collaterals[i].liqThreshold,
            // For reference, this is to simplify the interaction with the Aave protocol,
            // as there the definition is as e.g. 105% (5% bonus for liquidators)
            100_00 + collaterals[i].liqBonus
          );
        }

        if (collaterals[i].liqProtocolFee != EngineFlags.KEEP_CURRENT) {
          require(collaterals[i].liqProtocolFee < 100_00, 'INVALID_LIQ_PROTOCOL_FEE');
          POOL_CONFIGURATOR.setLiquidationProtocolFee(ids[i], collaterals[i].liqProtocolFee);
        }

        if (collaterals[i].debtCeiling != EngineFlags.KEEP_CURRENT) {
          // For reference, this is to simplify the interactions with the Aave protocol,
          // as there the definition is with 2 decimals. We don't see any reason to set
          // a debt ceiling involving .something USD, so we simply don't allow to do it
          POOL_CONFIGURATOR.setDebtCeiling(ids[i], collaterals[i].debtCeiling * 100);
        }
      }

      if (collaterals[i].eModeCategory != EngineFlags.KEEP_CURRENT) {
        POOL_CONFIGURATOR.setAssetEModeCategory(ids[i], safeToUint8(collaterals[i].eModeCategory));
      }
    }
  }

  function _repackListing(
    ListingWithCustomImpl[] memory listings
  ) internal pure returns (AssetsConfig memory) {
    address[] memory ids = new address[](listings.length);
    Basic[] memory basics = new Basic[](listings.length);
    Borrow[] memory borrows = new Borrow[](listings.length);
    Collateral[] memory collaterals = new Collateral[](listings.length);
    Caps[] memory caps = new Caps[](listings.length);
    IV3RateStrategyFactory.RateStrategyParams[]
      memory rates = new IV3RateStrategyFactory.RateStrategyParams[](listings.length);

    for (uint256 i = 0; i < listings.length; i++) {
      require(listings[i].base.asset != address(0), 'INVALID_ASSET');
      ids[i] = listings[i].base.asset;
      basics[i] = Basic({
        assetSymbol: listings[i].base.assetSymbol,
        priceFeed: listings[i].base.priceFeed,
        rateStrategyParams: listings[i].base.rateStrategyParams,
        implementations: listings[i].implementations
      });
      borrows[i] = Borrow({
        enabledToBorrow: listings[i].base.enabledToBorrow,
        flashloanable: listings[i].base.flashloanable,
        stableRateModeEnabled: listings[i].base.stableRateModeEnabled,
        borrowableInIsolation: listings[i].base.borrowableInIsolation,
        withSiloedBorrowing: listings[i].base.withSiloedBorrowing,
        reserveFactor: listings[i].base.reserveFactor
      });
      collaterals[i] = Collateral({
        ltv: listings[i].base.ltv,
        liqThreshold: listings[i].base.liqThreshold,
        liqBonus: listings[i].base.liqBonus,
        debtCeiling: listings[i].base.debtCeiling,
        liqProtocolFee: listings[i].base.liqProtocolFee,
        eModeCategory: listings[i].base.eModeCategory
      });
      caps[i] = Caps({
        supplyCap: listings[i].base.supplyCap,
        borrowCap: listings[i].base.borrowCap
      });
      rates[i] = listings[i].base.rateStrategyParams;
    }

    return
      AssetsConfig({
        ids: ids,
        basics: basics,
        borrows: borrows,
        collaterals: collaterals,
        caps: caps,
        rates: rates
      });
  }

  function _repackCapsUpdate(
    CapsUpdate[] memory updates
  ) internal pure returns (AssetsConfig memory) {
    address[] memory ids = new address[](updates.length);
    Caps[] memory caps = new Caps[](updates.length);

    for (uint256 i = 0; i < updates.length; i++) {
      ids[i] = updates[i].asset;
      caps[i] = Caps({supplyCap: updates[i].supplyCap, borrowCap: updates[i].borrowCap});
    }

    return
      AssetsConfig({
        ids: ids,
        caps: caps,
        basics: new Basic[](0),
        borrows: new Borrow[](0),
        collaterals: new Collateral[](0),
        rates: new IV3RateStrategyFactory.RateStrategyParams[](0)
      });
  }

  function _repackRatesUpdate(
    RateStrategyUpdate[] memory updates
  ) internal pure returns (AssetsConfig memory) {
    address[] memory ids = new address[](updates.length);
    IV3RateStrategyFactory.RateStrategyParams[]
      memory rates = new IV3RateStrategyFactory.RateStrategyParams[](updates.length);

    for (uint256 i = 0; i < updates.length; i++) {
      ids[i] = updates[i].asset;
      rates[i] = updates[i].params;
    }

    return
      AssetsConfig({
        ids: ids,
        rates: rates,
        basics: new Basic[](0),
        borrows: new Borrow[](0),
        caps: new Caps[](0),
        collaterals: new Collateral[](0)
      });
  }

  function _repackCollateralUpdate(
    CollateralUpdate[] memory updates
  ) internal pure returns (AssetsConfig memory) {
    address[] memory ids = new address[](updates.length);
    Collateral[] memory collaterals = new Collateral[](updates.length);

    for (uint256 i = 0; i < updates.length; i++) {
      ids[i] = updates[i].asset;
      collaterals[i] = Collateral({
        ltv: updates[i].ltv,
        liqThreshold: updates[i].liqThreshold,
        liqBonus: updates[i].liqBonus,
        debtCeiling: updates[i].debtCeiling,
        liqProtocolFee: updates[i].liqProtocolFee,
        eModeCategory: updates[i].eModeCategory
      });
    }

    return
      AssetsConfig({
        ids: ids,
        caps: new Caps[](0),
        basics: new Basic[](0),
        borrows: new Borrow[](0),
        collaterals: collaterals,
        rates: new IV3RateStrategyFactory.RateStrategyParams[](0)
      });
  }

  function _repackBorrowUpdate(
    BorrowUpdate[] memory updates
  ) internal pure returns (AssetsConfig memory) {
    address[] memory ids = new address[](updates.length);
    Borrow[] memory borrows = new Borrow[](updates.length);

    for (uint256 i = 0; i < updates.length; i++) {
      ids[i] = updates[i].asset;
      borrows[i] = Borrow({
        enabledToBorrow: updates[i].enabledToBorrow,
        flashloanable: updates[i].flashloanable,
        stableRateModeEnabled: updates[i].stableRateModeEnabled,
        borrowableInIsolation: updates[i].borrowableInIsolation,
        withSiloedBorrowing: updates[i].withSiloedBorrowing,
        reserveFactor: updates[i].reserveFactor
      });
    }

    return
      AssetsConfig({
        ids: ids,
        caps: new Caps[](0),
        basics: new Basic[](0),
        borrows: borrows,
        collaterals: new Collateral[](0),
        rates: new IV3RateStrategyFactory.RateStrategyParams[](0)
      });
  }

  function _repackPriceFeed(
    PriceFeedUpdate[] memory updates
  ) internal pure returns (AssetsConfig memory) {
    address[] memory ids = new address[](updates.length);
    Basic[] memory basics = new Basic[](updates.length);

    for (uint256 i = 0; i < updates.length; i++) {
      ids[i] = updates[i].asset;
      basics[i] = Basic({
        priceFeed: updates[i].priceFeed,
        assetSymbol: string(''), // unused for price feed update
        rateStrategyParams: IV3RateStrategyFactory.RateStrategyParams(0, 0, 0, 0, 0, 0, 0, 0, 0), // unused for price feed update
        implementations: TokenImplementations(address(0), address(0), address(0)) // unused for price feed update
      });
    }

    return
      AssetsConfig({
        ids: ids,
        caps: new Caps[](0),
        basics: basics,
        borrows: new Borrow[](0),
        collaterals: new Collateral[](0),
        rates: new IV3RateStrategyFactory.RateStrategyParams[](0)
      });
  }

  function safeToUint8(uint256 value) internal pure returns (uint8) {
    require(value <= type(uint8).max, 'Value doesnt fit in 8 bits');
    return uint8(value);
  }
}