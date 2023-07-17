// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IProposalExecutor} from './interfaces/IProposalExecutor.sol';
import {IAaveGenesisExecutor} from './interfaces/IAaveGenesisExecutor.sol';
import {IProxyWithAdminActions} from './interfaces/IProxyWithAdminActions.sol';
import {IERC20} from './interfaces/IERC20.sol';
import {IAssetVotingWeightProvider} from './interfaces/IAssetVotingWeightProvider.sol';
import {IStakedAaveConfig} from './interfaces/IStakedAaveConfig.sol';

/**
 * @title AaveGenesisProposalPayload
 * @notice Proposal payload to be executed by the Aave Governance contract via DELEGATECALL
 * - Transfers ownership of the different proxies to the `AaveGenesisExecutor`
 * - Lists AAVE and stkAAVE as voting asset in the Aave Governance
 * - Activates the cooldown for the activation of the LEND -> AAVE migration
 * @author Aave
 **/
contract AaveGenesisProposalPayload is IProposalExecutor {
  event ProposalExecuted();

  /// @dev Initial emission per second approved by the Aave community: 400 AAVE/day
  uint128 public constant EMISSION_PER_SECOND_FOR_STAKED_AAVE = 0.00462962962962963 ether;

  /// @dev Delta of blocks from the execution of this payload until the activation of the migration
  uint256 public immutable ACTIVATION_BLOCK_DELAY;

  /// @dev The smart contract that will execute the activation of the migration (`AaveGenesisExecutor`)
  IAaveGenesisExecutor public immutable AAVE_GENESIS_EXECUTOR;

  /// @dev The smart contract registry for the voting weights of all the whitelisted voting assets on the Aave governance
  IAssetVotingWeightProvider public immutable ASSET_VOTING_WEIGHT_PROVIDER;

  /// @dev Proxy contracts involved in the migration. This payload contract will need to transfer the admin rights of them,
  /// to allow it to do the upgrade of the implementations
  IProxyWithAdminActions public immutable LEND_TO_AAVE_MIGRATOR_PROXY;
  IProxyWithAdminActions public immutable AAVE_TOKEN_PROXY;
  IProxyWithAdminActions public immutable AAVE_INCENTIVES_VAULT_PROXY;
  IProxyWithAdminActions public immutable STAKED_AAVE_PROXY;

  /// @dev Address of wrapper aggregating LEND and aLEND balances
  address public immutable LEND_VOTE_STRATEGY_TOKEN;

  /// @dev Address of wrapper aggregating AAVE and stkAAVE balances
  address public immutable AAVE_VOTE_STRATEGY_TOKEN;

  constructor(
    uint256 activationBlockDelay,
    IAssetVotingWeightProvider assetVotingWeightProvider,
    IAaveGenesisExecutor aaveGenesisExecutor,
    IProxyWithAdminActions lendToAaveMigratorProxy,
    IProxyWithAdminActions aaveTokenProxy,
    IProxyWithAdminActions aaveIncentivesVaultProxy,
    IProxyWithAdminActions stakedAaveProxy,
    address lendVoteStrategyToken,
    address aaveVoteStrategyToken
  ) public {
    ACTIVATION_BLOCK_DELAY = activationBlockDelay;
    ASSET_VOTING_WEIGHT_PROVIDER = assetVotingWeightProvider;
    AAVE_GENESIS_EXECUTOR = aaveGenesisExecutor;
    LEND_TO_AAVE_MIGRATOR_PROXY = lendToAaveMigratorProxy;
    AAVE_TOKEN_PROXY = aaveTokenProxy;
    AAVE_INCENTIVES_VAULT_PROXY = aaveIncentivesVaultProxy;
    STAKED_AAVE_PROXY = stakedAaveProxy;
    LEND_VOTE_STRATEGY_TOKEN = lendVoteStrategyToken;
    AAVE_VOTE_STRATEGY_TOKEN = aaveVoteStrategyToken;
  }

  /**
   * @dev Payload execution function, called once a proposal passed in the Aave governance
   */
  function execute() external override {
    address newAdmin = address(AAVE_GENESIS_EXECUTOR);

    LEND_TO_AAVE_MIGRATOR_PROXY.changeAdmin(newAdmin);
    AAVE_TOKEN_PROXY.changeAdmin(newAdmin);
    AAVE_INCENTIVES_VAULT_PROXY.changeAdmin(newAdmin);
    STAKED_AAVE_PROXY.changeAdmin(newAdmin);

    // We disable the LEND voting strategy (LEND+aLEND)
    ASSET_VOTING_WEIGHT_PROVIDER.setVotingWeight(IERC20(LEND_VOTE_STRATEGY_TOKEN), 0);

    // We enable the AAVE voting strategy (AAVE+stkAAVE). As LEND is not listed already, they can have weight 1
    ASSET_VOTING_WEIGHT_PROVIDER.setVotingWeight(IERC20(AAVE_VOTE_STRATEGY_TOKEN), 1);

    // After transferring the admin to `newAdmin`, as this contract is the EMISSION_MANAGER of StakedAave,
    // we configure the initial emission of AAVE incentives
    IStakedAaveConfig.AssetConfigInput[] memory config = new IStakedAaveConfig.AssetConfigInput[](
      1
    );
    config[0] = IStakedAaveConfig.AssetConfigInput({
      emissionPerSecond: EMISSION_PER_SECOND_FOR_STAKED_AAVE,
      totalStaked: 0,
      underlyingAsset: address(STAKED_AAVE_PROXY)
    });

    IStakedAaveConfig(address(STAKED_AAVE_PROXY)).configureAssets(config);

    AAVE_GENESIS_EXECUTOR.setActivationBlock(block.number + ACTIVATION_BLOCK_DELAY);
    emit ProposalExecuted();
  }
}