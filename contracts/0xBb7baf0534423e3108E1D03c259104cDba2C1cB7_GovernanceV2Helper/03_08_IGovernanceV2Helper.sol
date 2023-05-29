// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import {IAaveGovernanceV2} from '../../interfaces/IAaveGovernanceV2.sol';
import {IExecutorWithTimelock} from '../../interfaces/IExecutorWithTimelock.sol';
import {
  IGovernancePowerDelegationToken
} from '../../interfaces/IGovernancePowerDelegationToken.sol';

interface IGovernanceV2Helper {
  struct ProposalStats {
    uint256 totalVotingSupply;
    uint256 minimumQuorum;
    uint256 minimumDiff;
    uint256 executionTimeWithGracePeriod;
    uint256 proposalCreated;
    uint256 id;
    address creator;
    IExecutorWithTimelock executor;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    uint256 startBlock;
    uint256 endBlock;
    uint256 executionTime;
    uint256 forVotes;
    uint256 againstVotes;
    bool executed;
    bool canceled;
    address strategy;
    bytes32 ipfsHash;
    IAaveGovernanceV2.ProposalState proposalState;
  }

  struct Power {
    uint256 votingPower;
    address delegatedAddressVotingPower;
    uint256 propositionPower;
    address delegatedAddressPropositionPower;
  }

  struct DelegateByTypeBySigParams {
    address delegatee;
    IGovernancePowerDelegationToken.DelegationType delegationType;
    uint256 nonce;
    uint256 expiry;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct DelegateBySigParams {
    address delegatee;
    uint256 nonce;
    uint256 expiry;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  function getProposals(
    uint256 skip,
    uint256 limit,
    IAaveGovernanceV2 governance
  ) external view virtual returns (ProposalStats[] memory proposalsStats);

  function getProposal(uint256 id, IAaveGovernanceV2 governance)
    external
    view
    virtual
    returns (ProposalStats memory proposalStats);

  function getTokensPower(address user, address[] memory tokens)
    external
    view
    virtual
    returns (Power[] memory power);

  function delegateTokensBySig(address[] calldata tokens, DelegateBySigParams[] calldata params)
    external;

  function delegateTokensByTypeBySig(
    address[] calldata tokens,
    DelegateByTypeBySigParams[] calldata params
  ) external;
}