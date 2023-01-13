// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {SynthereumPoolMigration} from './PoolMigration.sol';

/**
 * @title Abstract contract inherit by pools for moving storage from one pool to another
 */
abstract contract SynthereumPoolMigrationTo is SynthereumPoolMigration {
  /**
   * @notice Migrate storage to this new pool and initialize it
   * @param _finder Synthereum finder of the pool
   * @param _oldVersion Version of the migrated pool
   * @param _storageBytes Pool storage encoded in bytes
   * @param _newVersion Version of the new deployed pool
   * @param _extraInputParams Additive input pool params encoded for the new pool, that are not part of the migrationPool
   * @param _sourceCollateralAmount Collateral amount from the source pool
   * @param _actualCollateralAmount Collateral amount of the new pool
   * @param _price Actual price of the pair
   */
  function setMigratedStorage(
    ISynthereumFinder _finder,
    uint8 _oldVersion,
    bytes calldata _storageBytes,
    uint8 _newVersion,
    bytes calldata _extraInputParams,
    uint256 _sourceCollateralAmount,
    uint256 _actualCollateralAmount,
    uint256 _price
  ) external virtual {
    finder = _finder;
    _setMigratedStorage(
      _oldVersion,
      _storageBytes,
      _newVersion,
      _extraInputParams,
      _sourceCollateralAmount,
      _actualCollateralAmount,
      _price
    );
  }

  /**
   * @notice Migrate storage to this new pool and initialize it
   * @notice This can be called only by a pool factory
   * @param _oldVersion Version of the migrated pool
   * @param _storageBytes Pool storage encoded in bytes
   * @param _newVersion Version of the new deployed pool
   * @param _extraInputParams Additive input pool params encoded for the new pool, that are not part of the migrationPool
   * @param _sourceCollateralAmount Collateral amount from the source pool
   * @param _actualCollateralAmount Collateral amount of the new pool
   * @param _price Actual price of the pair
   */
  function _setMigratedStorage(
    uint8 _oldVersion,
    bytes calldata _storageBytes,
    uint8 _newVersion,
    bytes calldata _extraInputParams,
    uint256 _sourceCollateralAmount,
    uint256 _actualCollateralAmount,
    uint256 _price
  ) internal onlyPoolFactory {
    _setStorage(_oldVersion, _storageBytes, _newVersion, _extraInputParams);
    _modifyStorageTo(_sourceCollateralAmount, _actualCollateralAmount, _price);
  }

  /**
   * @notice Function to implement for setting the storage to the new pool
   * @param _oldVersion Version of the migrated pool
   * @param _storageBytes Pool storage encoded in bytes
   * @param _newVersion Version of the new deployed pool
   * @param _extraInputParams Additive input pool params encoded for the new pool, that are not part of the migrationPool
   */
  function _setStorage(
    uint8 _oldVersion,
    bytes calldata _storageBytes,
    uint8 _newVersion,
    bytes calldata _extraInputParams
  ) internal virtual;

  /**
   * @notice Function to implement for modifying the storage of the new pool after the migration
   * @param _sourceCollateralAmount Collateral amount from the source pool
   * @param _actualCollateralAmount Collateral amount of the new pool
   * @param _price Actual price of the pair
   */
  function _modifyStorageTo(
    uint256 _sourceCollateralAmount,
    uint256 _actualCollateralAmount,
    uint256 _price
  ) internal virtual;
}