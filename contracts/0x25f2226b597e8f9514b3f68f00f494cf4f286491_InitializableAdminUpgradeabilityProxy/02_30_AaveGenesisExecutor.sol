// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IProxyWithAdminActions} from './interfaces/IProxyWithAdminActions.sol';
import {
  ILendToAaveMigratorImplWithInitialize
} from './interfaces/ILendToAaveMigratorImplWithInitialize.sol';
import {IAaveTokenImpl} from './interfaces/IAaveTokenImpl.sol';
import {
  IAaveIncentivesVaultImplWithInitialize
} from './interfaces/IAaveIncentivesVaultImplWithInitialize.sol';
import {IStakedAaveImplWithInitialize} from './interfaces/IStakedAaveImplWithInitialize.sol';

import {IAaveGenesisExecutor} from './interfaces/IAaveGenesisExecutor.sol';

/**
 * @title AaveGenesisExecutor
 * @notice Smart contract to trigger the LEND -> AAVE migration and enable the staking Safety Module
 * - The Aave Governance, on the payload of the proposal will call `setActivationBlock()` with the block
 *   number at which the migration and staking starts
 * - Once that block number is reached, `startMigration()` will be opened to call by anybody, to execute the
 *   programmed process
 * - As to execute all the operations with proxy contracts this contract needs to be the admin, a `returnAdminsToGovernance()`
 *   function has be added to return back the admin rights to the Aave Governance if after 1 day of the `activationBlock` the
 *   ownership of the proxies is still on this contract
 * @author Aave
 **/
contract AaveGenesisExecutor is IAaveGenesisExecutor {
  address public immutable AAVE_GOVERNANCE;
  IProxyWithAdminActions public immutable LEND_TO_AAVE_MIGRATOR_PROXY;
  ILendToAaveMigratorImplWithInitialize public immutable LEND_TO_AAVE_MIGRATOR_IMPL;
  IProxyWithAdminActions public immutable AAVE_TOKEN_PROXY;
  IAaveTokenImpl public immutable AAVE_TOKEN_IMPL;
  IProxyWithAdminActions public immutable AAVE_INCENTIVES_VAULT_PROXY;
  IAaveIncentivesVaultImplWithInitialize public immutable AAVE_INCENTIVES_VAULT_IMPL;
  IProxyWithAdminActions public immutable STAKED_AAVE_PROXY;

  /// @dev Number of blocks per day
  uint256 public constant BLOCKS_PER_DAY = 6650;

  /// @dev Allowance of AAVE given by the AaveIncentivesVault to the StakedAave to pull incentives for stakers
  uint256 public immutable AAVE_ALLOWANCE_FOR_STAKE;

  /// @dev Block number of when the activateMigration() will be triggered
  uint256 internal activationBlock;

  constructor(
    address aaveGovernance,
    uint256 aaveAllowanceForStake,
    IProxyWithAdminActions lendToAaveMigratorProxy,
    ILendToAaveMigratorImplWithInitialize lendToAaveMigratorImpl,
    IProxyWithAdminActions aaveTokenProxy,
    IAaveTokenImpl aaveTokenImpl,
    IProxyWithAdminActions aaveIncentivesVaultProxy,
    IAaveIncentivesVaultImplWithInitialize aaveIncentivesVaultImpl,
    IProxyWithAdminActions stakedAaveProxy
  ) public {
    AAVE_GOVERNANCE = aaveGovernance;
    AAVE_ALLOWANCE_FOR_STAKE = aaveAllowanceForStake;
    LEND_TO_AAVE_MIGRATOR_PROXY = lendToAaveMigratorProxy;
    LEND_TO_AAVE_MIGRATOR_IMPL = lendToAaveMigratorImpl;
    AAVE_TOKEN_PROXY = aaveTokenProxy;
    AAVE_TOKEN_IMPL = aaveTokenImpl;
    AAVE_INCENTIVES_VAULT_PROXY = aaveIncentivesVaultProxy;
    AAVE_INCENTIVES_VAULT_IMPL = aaveIncentivesVaultImpl;
    STAKED_AAVE_PROXY = stakedAaveProxy;
  }

  /**
   * @dev Called by the Aave Governance contract to set the block at which the LEND -> AAVE and the staking will start
   * @param blockNumber The future block number
   */
  function setActivationBlock(uint256 blockNumber) external override {
    require(msg.sender == AAVE_GOVERNANCE);

    activationBlock = blockNumber;

    emit MigrationProgrammedForBlock(blockNumber);
  }

  /**
   * @dev Once the `activationBlock` is reached, this funcion can be called by anybody to trigger the migration + startup of staking
   */
  function startMigration() external override {
    // ensures that the migration can only be called after the initialization has been performed
    require(activationBlock != 0 && block.number >= activationBlock);

    // step 1: Initializes the LendToAaveMigrator to enable the migration contract
    bytes memory migratorParams = abi.encodeWithSelector(
      LEND_TO_AAVE_MIGRATOR_IMPL.initialize.selector
    );
    LEND_TO_AAVE_MIGRATOR_PROXY.upgradeToAndCall(
      address(LEND_TO_AAVE_MIGRATOR_IMPL),
      migratorParams
    );

    // step 2: Initializes the AAVE token. The initialization triggers the following events:
    // - 13M AAVE are minted to the LendToAaveMigrator, which enables the migration process
    // - 3M AAVE are minted to the incentives vault
    bytes memory aaveTokenParams = abi.encodeWithSelector(
      AAVE_TOKEN_IMPL.initialize.selector,
      address(LEND_TO_AAVE_MIGRATOR_PROXY),
      address(AAVE_INCENTIVES_VAULT_PROXY), // Where the incentives will be minted to
      address(0) // No hook to the governance is needed for now on the AaveToken
    );
    AAVE_TOKEN_PROXY.upgradeToAndCall(address(AAVE_TOKEN_IMPL), aaveTokenParams);

    // step 3: Initializes the Aave incentives vault.
    // The initialization will approve the Aave stake to pull funds from the vault in order to distribute
    // staking incentives
    bytes memory aaveIncentivesVaultParams = abi.encodeWithSelector(
      AAVE_INCENTIVES_VAULT_IMPL.initialize.selector,
      address(AAVE_TOKEN_PROXY),
      address(STAKED_AAVE_PROXY), // The StakedAave will be approved to pull AAVE for incentives
      AAVE_ALLOWANCE_FOR_STAKE
    );
    AAVE_INCENTIVES_VAULT_PROXY.upgradeToAndCall(
      address(AAVE_INCENTIVES_VAULT_IMPL),
      aaveIncentivesVaultParams
    );

    _returnAdminsToGovernance();

    emit MigrationStarted();
  }

  /**
   * @dev Emergency function to return the admin rights on all the proxy contracts if something went wrong on `startMigration()`.
   * - Anybody can call it once > ~1 day in blocks passed since the `activationBlock`
   */
  function returnAdminsToGovernance() external override {
    require(activationBlock != 0 && block.number >= activationBlock + BLOCKS_PER_DAY);

    _returnAdminsToGovernance();
  }

  function _returnAdminsToGovernance() private {
    LEND_TO_AAVE_MIGRATOR_PROXY.changeAdmin(AAVE_GOVERNANCE);
    AAVE_TOKEN_PROXY.changeAdmin(AAVE_GOVERNANCE);
    AAVE_INCENTIVES_VAULT_PROXY.changeAdmin(AAVE_GOVERNANCE);
    STAKED_AAVE_PROXY.changeAdmin(AAVE_GOVERNANCE);
  }
}