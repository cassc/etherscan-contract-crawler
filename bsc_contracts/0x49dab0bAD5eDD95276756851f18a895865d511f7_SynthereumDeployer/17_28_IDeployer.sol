// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumDeployment} from '../../common/interfaces/IDeployment.sol';
import {
  SynthereumPoolMigrationFrom
} from '../../synthereum-pool/common/migration/PoolMigrationFrom.sol';

/**
 * @title Provides interface with functions of Synthereum deployer
 */
interface ISynthereumDeployer {
  /**
   * @notice Deploy a new pool
   * @param _poolVersion Version of the pool contract
   * @param _poolParamsData Input params of pool constructor
   * @return pool Pool contract deployed
   */
  function deployPool(uint8 _poolVersion, bytes calldata _poolParamsData)
    external
    returns (ISynthereumDeployment pool);

  /**
   * @notice Migrate storage of an existing pool to e new deployed one
   * @param _migrationPool Pool from which migrate storage
   * @param _poolVersion Version of the pool contract to create
   * @param _migrationParamsData Input params of migration (if needed)
   * @return pool Pool contract deployed
   */
  function migratePool(
    SynthereumPoolMigrationFrom _migrationPool,
    uint8 _poolVersion,
    bytes calldata _migrationParamsData
  ) external returns (ISynthereumDeployment pool);

  /**
   * @notice Remove from the registry an existing pool
   * @param _pool Pool to remove
   */
  function removePool(ISynthereumDeployment _pool) external;

  /**
   * @notice Deploy a new self minting derivative contract
   * @param _selfMintingDerVersion Version of the self minting derivative contract
   * @param _selfMintingDerParamsData Input params of self minting derivative constructor
   * @return selfMintingDerivative Self minting derivative contract deployed
   */
  function deploySelfMintingDerivative(
    uint8 _selfMintingDerVersion,
    bytes calldata _selfMintingDerParamsData
  ) external returns (ISynthereumDeployment selfMintingDerivative);

  /**
   * @notice Remove from the registry an existing self-minting derivativ contract
   * @param _selfMintingDerivative Self-minting derivative to remove
   */
  function removeSelfMintingDerivative(
    ISynthereumDeployment _selfMintingDerivative
  ) external;

  /**
   * @notice Deploy a new fixed rate wrapper contract
   * @param _fixedRateVersion Version of the fixed rate wrapper contract
   * @param _fixedRateParamsData Input params of fixed rate wrapper constructor
   * @return fixedRate Fixed rate wrapper contract deployed
   */
  function deployFixedRate(
    uint8 _fixedRateVersion,
    bytes calldata _fixedRateParamsData
  ) external returns (ISynthereumDeployment fixedRate);

  /**
   * @notice Remove from the registry a fixed rate wrapper
   * @param _fixedRate Fixed-rate to remove
   */
  function removeFixedRate(ISynthereumDeployment _fixedRate) external;
}