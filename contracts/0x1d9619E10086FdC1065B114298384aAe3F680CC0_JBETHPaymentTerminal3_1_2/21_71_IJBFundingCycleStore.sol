// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {JBBallotState} from './../enums/JBBallotState.sol';
import {JBFundingCycle} from './../structs/JBFundingCycle.sol';
import {JBFundingCycleData} from './../structs/JBFundingCycleData.sol';

interface IJBFundingCycleStore {
  event Configure(
    uint256 indexed configuration,
    uint256 indexed projectId,
    JBFundingCycleData data,
    uint256 metadata,
    uint256 mustStartAtOrAfter,
    address caller
  );

  event Init(uint256 indexed configuration, uint256 indexed projectId, uint256 indexed basedOn);

  function latestConfigurationOf(uint256 projectId) external view returns (uint256);

  function get(
    uint256 projectId,
    uint256 configuration
  ) external view returns (JBFundingCycle memory);

  function latestConfiguredOf(
    uint256 projectId
  ) external view returns (JBFundingCycle memory fundingCycle, JBBallotState ballotState);

  function queuedOf(uint256 projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentOf(uint256 projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentBallotStateOf(uint256 projectId) external view returns (JBBallotState);

  function configureFor(
    uint256 projectId,
    JBFundingCycleData calldata data,
    uint256 metadata,
    uint256 mustStartAtOrAfter
  ) external returns (JBFundingCycle memory fundingCycle);
}