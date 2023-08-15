// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {JBBallotState} from './../enums/JBBallotState.sol';
import {JBFundAccessConstraints} from './../structs/JBFundAccessConstraints.sol';
import {JBFundingCycle} from './../structs/JBFundingCycle.sol';
import {JBFundingCycleData} from './../structs/JBFundingCycleData.sol';
import {JBFundingCycleMetadata} from './../structs/JBFundingCycleMetadata.sol';
import {JBGroupedSplits} from './../structs/JBGroupedSplits.sol';
import {JBProjectMetadata} from './../structs/JBProjectMetadata.sol';
import {JBSplit} from './../structs/JBSplit.sol';
import {IJBDirectory} from './IJBDirectory.sol';
import {IJBFundingCycleStore} from './IJBFundingCycleStore.sol';
import {IJBMigratable} from './IJBMigratable.sol';
import {IJBPaymentTerminal} from './IJBPaymentTerminal.sol';
import {IJBProjects} from './IJBProjects.sol';
import {IJBSplitsStore} from './IJBSplitsStore.sol';
import {IJBTokenStore} from './IJBTokenStore.sol';

interface IJBController is IERC165 {
  event LaunchProject(uint256 configuration, uint256 projectId, string memo, address caller);

  event LaunchFundingCycles(uint256 configuration, uint256 projectId, string memo, address caller);

  event ReconfigureFundingCycles(
    uint256 configuration,
    uint256 projectId,
    string memo,
    address caller
  );

  event SetFundAccessConstraints(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    JBFundAccessConstraints constraints,
    address caller
  );

  event DistributeReservedTokens(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address beneficiary,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    address caller
  );

  event DistributeToReservedTokenSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    uint256 tokenCount,
    address caller
  );

  event MintTokens(
    address indexed beneficiary,
    uint256 indexed projectId,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    uint256 reservedRate,
    address caller
  );

  event BurnTokens(
    address indexed holder,
    uint256 indexed projectId,
    uint256 tokenCount,
    string memo,
    address caller
  );

  event Migrate(uint256 indexed projectId, IJBMigratable to, address caller);

  event PrepMigration(uint256 indexed projectId, address from, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function tokenStore() external view returns (IJBTokenStore);

  function splitsStore() external view returns (IJBSplitsStore);

  function directory() external view returns (IJBDirectory);

  function reservedTokenBalanceOf(
    uint256 projectId,
    uint256 reservedRate
  ) external view returns (uint256);

  function distributionLimitOf(
    uint256 projectId,
    uint256 configuration,
    IJBPaymentTerminal terminal,
    address token
  ) external view returns (uint256 distributionLimit, uint256 distributionLimitCurrency);

  function overflowAllowanceOf(
    uint256 projectId,
    uint256 configuration,
    IJBPaymentTerminal terminal,
    address token
  ) external view returns (uint256 overflowAllowance, uint256 overflowAllowanceCurrency);

  function totalOutstandingTokensOf(
    uint256 projectId,
    uint256 reservedRate
  ) external view returns (uint256);

  function getFundingCycleOf(
    uint256 projectId,
    uint256 configuration
  )
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function latestConfiguredFundingCycleOf(
    uint256 projectId
  )
    external
    view
    returns (JBFundingCycle memory, JBFundingCycleMetadata memory metadata, JBBallotState);

  function currentFundingCycleOf(
    uint256 projectId
  )
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function queuedFundingCycleOf(
    uint256 projectId
  )
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function launchProjectFor(
    address owner,
    JBProjectMetadata calldata projectMetadata,
    JBFundingCycleData calldata data,
    JBFundingCycleMetadata calldata metadata,
    uint256 mustStartAtOrAfter,
    JBGroupedSplits[] memory groupedSplits,
    JBFundAccessConstraints[] memory fundAccessConstraints,
    IJBPaymentTerminal[] memory terminals,
    string calldata memo
  ) external returns (uint256 projectId);

  function launchFundingCyclesFor(
    uint256 projectId,
    JBFundingCycleData calldata data,
    JBFundingCycleMetadata calldata metadata,
    uint256 mustStartAtOrAfter,
    JBGroupedSplits[] memory groupedSplits,
    JBFundAccessConstraints[] memory fundAccessConstraints,
    IJBPaymentTerminal[] memory terminals,
    string calldata memo
  ) external returns (uint256 configuration);

  function reconfigureFundingCyclesOf(
    uint256 projectId,
    JBFundingCycleData calldata data,
    JBFundingCycleMetadata calldata metadata,
    uint256 mustStartAtOrAfter,
    JBGroupedSplits[] memory groupedSplits,
    JBFundAccessConstraints[] memory fundAccessConstraints,
    string calldata memo
  ) external returns (uint256);

  function mintTokensOf(
    uint256 projectId,
    uint256 tokenCount,
    address beneficiary,
    string calldata memo,
    bool preferClaimedTokens,
    bool useReservedRate
  ) external returns (uint256 beneficiaryTokenCount);

  function burnTokensOf(
    address holder,
    uint256 projectId,
    uint256 tokenCount,
    string calldata memo,
    bool preferClaimedTokens
  ) external;

  function distributeReservedTokensOf(
    uint256 projectId,
    string memory memo
  ) external returns (uint256);

  function migrate(uint256 projectId, IJBMigratable to) external;
}