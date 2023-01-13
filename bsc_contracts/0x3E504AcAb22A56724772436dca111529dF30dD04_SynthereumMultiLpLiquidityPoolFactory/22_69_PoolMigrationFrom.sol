// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {SynthereumPoolMigration} from './PoolMigration.sol';

/**
 * @title Abstract contract inherit by pools for moving storage from one pool to another
 */
abstract contract SynthereumPoolMigrationFrom is SynthereumPoolMigration {
  /**
   * @notice Migrate storage from this pool resetting and cleaning data
   * @notice This can be called only by a pool factory
   * @return poolVersion Version of the pool
   * @return price Actual price of the pair
   * @return storageBytes Pool storage encoded in bytes
   */
  function migrateStorage()
    external
    virtual
    onlyPoolFactory
    returns (
      uint8 poolVersion,
      uint256 price,
      bytes memory storageBytes
    )
  {
    _modifyStorageFrom();
    (poolVersion, price, storageBytes) = _encodeStorage();
    _cleanStorage();
  }

  /**
   * @notice Transfer all bearing tokens to another address
   * @notice Only the lending manager can call the function
   * @param _recipient Address receving bearing amount
   * @return migrationAmount Total balance of the pool in bearing tokens before migration
   */
  function migrateTotalFunds(address _recipient)
    external
    virtual
    returns (uint256 migrationAmount);

  /**
   * @notice Function to implement for modifying storage before the encoding
   */
  function _modifyStorageFrom() internal virtual;

  /**
   * @notice Function to implement for cleaning and resetting the storage to the initial state
   */
  function _cleanStorage() internal virtual;

  /**
   * @notice Function to implement for encoding storage in bytes
   * @return poolVersion Version of the pool
   * @return price Actual price of the pair
   * @return storageBytes Pool storage encoded in bytes
   */
  function _encodeStorage()
    internal
    view
    virtual
    returns (
      uint8 poolVersion,
      uint256 price,
      bytes memory storageBytes
    );
}