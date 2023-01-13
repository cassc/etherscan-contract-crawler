// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ILendingManager
} from '../../lending-module/interfaces/ILendingManager.sol';
import {
  ISynthereumMultiLpLiquidityPool
} from './interfaces/IMultiLpLiquidityPool.sol';
import {
  ISynthereumPoolMigrationStorage
} from '../common/migration/interfaces/IPoolMigrationStorage.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {
  EnumerableSet
} from '../../../@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {SynthereumMultiLpLiquidityPoolLib} from './MultiLpLiquidityPoolLib.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

/**
 * @title Multi LP Synthereum pool lib for migration of the storage
 */

library SynthereumMultiLpLiquidityPoolMigrationLib {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  struct TempListArgs {
    address[] admins;
    address[] maintainers;
    address[] registeredLps;
    address[] activeLps;
  }

  /**
   * @notice Set new lending protocol for this pool
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _lendingId Name of the new lending module
   * @param _bearingToken Token of the lending mosule to be used for intersts accrual
            (used only if the lending manager doesn't automatically find the one associated to the collateral fo this pool)
   * @param _finder Synthereum finder
   */
  function switchLendingModule(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    string calldata _lendingId,
    address _bearingToken,
    ISynthereumFinder _finder
  ) external {
    require(
      msg.sender ==
        _finder.getImplementationAddress(SynthereumInterfaces.Manager),
      'Sender must be the Synthereum manager'
    );

    ILendingManager.MigrateReturnValues memory migrationValues =
      SynthereumMultiLpLiquidityPoolLib._lendingMigration(
        SynthereumMultiLpLiquidityPoolLib._getLendingManager(_finder),
        SynthereumMultiLpLiquidityPoolLib._getLendingStorageManager(_finder),
        _lendingId,
        _bearingToken
      );

    SynthereumMultiLpLiquidityPoolLib.TempStorageArgs memory tempStorage =
      SynthereumMultiLpLiquidityPoolLib.TempStorageArgs(
        SynthereumMultiLpLiquidityPoolLib._getPriceFeedRate(
          _finder,
          _storageParams.priceIdentifier
        ),
        _storageParams.totalSyntheticAsset,
        _storageParams.collateralDecimals
      );

    (
      SynthereumMultiLpLiquidityPoolLib.PositionCache[] memory positionsCache,
      uint256 prevTotalLpsCollateral,
      uint256 mostFundedIndex
    ) =
      SynthereumMultiLpLiquidityPoolLib._calculateNewPositions(
        _storageParams,
        migrationValues.poolInterest,
        tempStorage.price,
        tempStorage.totalSyntheticAsset,
        migrationValues.prevTotalCollateral,
        tempStorage.decimals
      );

    SynthereumMultiLpLiquidityPoolLib._calculateSwitchingOrMigratingCollateral(
      prevTotalLpsCollateral,
      migrationValues,
      _storageParams.overCollateralRequirement,
      tempStorage.price,
      tempStorage.decimals,
      mostFundedIndex,
      positionsCache
    );

    SynthereumMultiLpLiquidityPoolLib._updateActualLPPositions(
      _storageParams,
      positionsCache
    );

    SynthereumMultiLpLiquidityPoolLib._setLendingModule(
      _storageParams,
      _lendingId
    );
  }

  /**
   * @notice Reset storage to the initial status
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _registeredLPsList List of every registered LP
   * @param _activeLPsList List of every active LP
   */
  function cleanStorage(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    address[] calldata _registeredLPsList,
    address[] calldata _activeLPsList
  ) external {
    address lp;
    for (uint256 j = 0; j < _activeLPsList.length; j++) {
      lp = _activeLPsList[j];
      _storageParams.activeLPs.remove(lp);
      delete _storageParams.lpPositions[lp];
    }
    for (uint256 j = 0; j < _registeredLPsList.length; j++) {
      _storageParams.registeredLPs.remove(_registeredLPsList[j]);
    }
    delete _storageParams.totalSyntheticAsset;
  }

  /**
   * @notice Set the storage to the new pool during migration
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _oldVersion Version of the migrated pool
   * @param _storageBytes Pool storage encoded in bytes
   * @param _newVersion Version of the new deployed pool
   * @param _extraInputParams Additive input pool params encoded for the new pool, that are not part of the migrationPool
   * @return admins List of pool admins
   * @return maintainers List of pool maintainers
   */
  function setStorage(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    uint8 _oldVersion,
    bytes calldata _storageBytes,
    uint8 _newVersion,
    bytes calldata _extraInputParams
  ) external returns (address[] memory admins, address[] memory maintainers) {
    _storageParams.poolVersion = _newVersion;

    ISynthereumPoolMigrationStorage.MigrationV6 memory migrationStorage =
      abi.decode(_storageBytes, (ISynthereumPoolMigrationStorage.MigrationV6));

    _storageParams.lendingModuleId = migrationStorage.lendingModuleId;
    _storageParams.priceIdentifier = migrationStorage.priceIdentifier;
    _storageParams.totalSyntheticAsset = migrationStorage.totalSyntheticAsset;
    _storageParams.collateralAsset = migrationStorage.collateralAsset;
    _storageParams.fee = migrationStorage.fee;
    _storageParams.collateralDecimals = migrationStorage.collateralDecimals;
    _storageParams.overCollateralRequirement = migrationStorage
      .overCollateralRequirement;
    _storageParams.liquidationBonus = migrationStorage.liquidationBonus;
    _storageParams.syntheticAsset = migrationStorage.syntheticAsset;

    address lp;
    for (uint256 j = 0; j < migrationStorage.activeLPsList.length; j++) {
      lp = migrationStorage.activeLPsList[j];
      _storageParams.activeLPs.add(lp);
      _storageParams.lpPositions[lp] = migrationStorage.positions[j];
    }

    for (uint256 j = 0; j < migrationStorage.registeredLPsList.length; j++) {
      _storageParams.registeredLPs.add(migrationStorage.registeredLPsList[j]);
    }

    admins = migrationStorage.admins;
    maintainers = migrationStorage.maintainers;
  }

  /**
   * @notice Update storage after the migration, splitting fee/bonus of the migration between the LPs
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _sourceCollateralAmount Collateral amount from the source pool
   * @param _actualCollateralAmount Collateral amount of the new pool
   * @param _price Actual price of the pair
   */
  function updateMigrationStorage(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    uint256 _sourceCollateralAmount,
    uint256 _actualCollateralAmount,
    uint256 _price
  ) external {
    uint256 lpNumbers = _storageParams.activeLPs.length();
    if (lpNumbers > 0) {
      SynthereumMultiLpLiquidityPoolLib.PositionCache[] memory positionsCache =
        new SynthereumMultiLpLiquidityPoolLib.PositionCache[](lpNumbers);
      (uint256 totalLpsCollateral, uint256 mostFundedIndex) =
        SynthereumMultiLpLiquidityPoolLib._loadPositions(
          _storageParams,
          positionsCache
        );
      SynthereumMultiLpLiquidityPoolLib
        ._calculateSwitchingOrMigratingCollateral(
        totalLpsCollateral,
        ILendingManager.MigrateReturnValues(
          _sourceCollateralAmount,
          0,
          _actualCollateralAmount
        ),
        _storageParams.overCollateralRequirement,
        _price,
        _storageParams.collateralDecimals,
        mostFundedIndex,
        positionsCache
      );
      SynthereumMultiLpLiquidityPoolLib._updateActualLPPositions(
        _storageParams,
        positionsCache
      );
    }
  }

  /**
   * @notice Encode storage of the pool in bytes for migration
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _lists Lists of admins, maintainers, registered and active LPs
   * @param _finder Synthereum finder
   * @return poolVersion Version of the pool
   * @return price Actual price of the pair
   * @return storageBytes Encoded pool storage in bytes
   */
  function encodeStorage(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    TempListArgs calldata _lists,
    ISynthereumFinder _finder
  )
    external
    view
    returns (
      uint8 poolVersion,
      uint256 price,
      bytes memory storageBytes
    )
  {
    poolVersion = _storageParams.poolVersion;
    bytes32 priceIdentifier = _storageParams.priceIdentifier;
    price = SynthereumMultiLpLiquidityPoolLib._getPriceFeedRate(
      _finder,
      priceIdentifier
    );
    uint256 numberOfLps = _lists.activeLps.length;
    ISynthereumMultiLpLiquidityPool.LPPosition[] memory positions =
      new ISynthereumMultiLpLiquidityPool.LPPosition[](numberOfLps);
    for (uint256 j = 0; j < numberOfLps; j++) {
      positions[j] = _storageParams.lpPositions[_lists.activeLps[j]];
    }
    storageBytes = abi.encode(
      ISynthereumPoolMigrationStorage.MigrationV6(
        _storageParams.lendingModuleId,
        priceIdentifier,
        _storageParams.totalSyntheticAsset,
        _storageParams.collateralAsset,
        _storageParams.fee,
        _storageParams.collateralDecimals,
        _storageParams.overCollateralRequirement,
        _storageParams.liquidationBonus,
        _storageParams.syntheticAsset,
        _lists.registeredLps,
        _lists.activeLps,
        positions,
        _lists.admins,
        _lists.maintainers
      )
    );
  }

  /**
   * @notice Transfer all bearing tokens to another address
   * @notice Only the lending manager can call the function
   * @param _recipient Address receving bearing amount
   * @param _finder Synthereum finder
   * @return migrationAmount Total balance of the pool in bearing tokens before migration
   */
  function migrateTotalFunds(address _recipient, ISynthereumFinder _finder)
    external
    returns (uint256 migrationAmount)
  {
    ILendingManager lendingManager =
      SynthereumMultiLpLiquidityPoolLib._getLendingManager(_finder);
    require(
      msg.sender == address(lendingManager),
      'Sender must be the lending manager'
    );

    IERC20 bearingToken =
      IERC20(
        SynthereumMultiLpLiquidityPoolLib
          ._getLendingStorageManager(_finder)
          .getInterestBearingToken(address(this))
      );
    migrationAmount = bearingToken.balanceOf(address(this));
    bearingToken.safeTransfer(_recipient, migrationAmount);
  }
}