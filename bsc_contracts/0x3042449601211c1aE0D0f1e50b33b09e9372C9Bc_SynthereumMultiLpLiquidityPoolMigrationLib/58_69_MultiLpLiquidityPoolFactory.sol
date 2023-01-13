// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {
  IDeploymentSignature
} from '../../core/interfaces/IDeploymentSignature.sol';
import {
  IMigrationSignature
} from '../../core/interfaces/IMigrationSignature.sol';
import {
  SynthereumMultiLpLiquidityPoolCreator
} from './MultiLpLiquidityPoolCreator.sol';
import {FactoryConditions} from '../../common/FactoryConditions.sol';
import {
  SynthereumPoolMigrationFrom
} from '../common/migration/PoolMigrationFrom.sol';
import {
  ReentrancyGuard
} from '../../../@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {SynthereumMultiLpLiquidityPool} from './MultiLpLiquidityPool.sol';

contract SynthereumMultiLpLiquidityPoolFactory is
  IMigrationSignature,
  IDeploymentSignature,
  ReentrancyGuard,
  FactoryConditions,
  SynthereumMultiLpLiquidityPoolCreator
{
  //----------------------------------------
  // Storage
  //----------------------------------------

  bytes4 public immutable override deploymentSignature;

  bytes4 public immutable override migrationSignature;

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Set synthereum finder
   * @param _synthereumFinder Synthereum finder contract
   * @param _poolImplementation Address of the deployed pool implementation used for EIP1167
   */
  constructor(address _synthereumFinder, address _poolImplementation)
    SynthereumMultiLpLiquidityPoolCreator(
      _synthereumFinder,
      _poolImplementation
    )
  {
    deploymentSignature = this.createPool.selector;
    migrationSignature = this.migratePool.selector;
  }

  //----------------------------------------
  // Public functions
  //----------------------------------------

  /**
   * @notice Deploy a pool
   * @notice Only the deployer can call this function
   * @param params input parameters of the pool
   * @return pool Deployed pool
   */
  function createPool(Params calldata params)
    public
    override
    onlyDeployer(synthereumFinder)
    nonReentrant
    returns (SynthereumMultiLpLiquidityPool pool)
  {
    checkDeploymentConditions(
      synthereumFinder,
      params.collateralToken,
      params.priceIdentifier
    );
    pool = super.createPool(params);
  }

  /**
   * @notice Migrate storage from a pool to a new depolyed one
   * @notice Only the deployer can call this function
   * @param _migrationPool Pool from which migrate storage
   * @param _version Version of the new pool
   * @param _extraInputParams Additive input pool params encoded for the new pool, that are not part of the migrationPool
   * @return migrationPoolUsed Pool from which migrate storage
   * @return pool address of the new deployed pool contract to which storage is migrated
   */
  function migratePool(
    SynthereumPoolMigrationFrom _migrationPool,
    uint8 _version,
    bytes calldata _extraInputParams
  )
    public
    override
    nonReentrant
    onlyDeployer(synthereumFinder)
    returns (
      SynthereumPoolMigrationFrom migrationPoolUsed,
      SynthereumMultiLpLiquidityPool pool
    )
  {
    (migrationPoolUsed, pool) = super.migratePool(
      _migrationPool,
      _version,
      _extraInputParams
    );
  }
}