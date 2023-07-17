// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {IExecutorWithTimelock} from './IExecutorWithTimelock.sol';
import {IVotingPowerStrategy} from './IVotingPowerStrategy.sol';

interface IKyberGovernance {
  enum ProposalState {
    Pending,
    Canceled,
    Active,
    Failed,
    Succeeded,
    Queued,
    Expired,
    Executed,
    Finalized
  }
  enum ProposalType {Generic, Binary}

  /// For Binary proposal, optionBitMask is 0/1/2
  /// For Generic proposal, optionBitMask is bitmask of voted options
  struct Vote {
    uint32 optionBitMask;
    uint224 votingPower;
  }

  struct ProposalWithoutVote {
    uint256 id;
    ProposalType proposalType;
    address creator;
    IExecutorWithTimelock executor;
    IVotingPowerStrategy strategy;
    address[] targets;
    uint256[] weiValues;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    string[] options;
    uint256[] voteCounts;
    uint256 totalVotes;
    uint256 maxVotingPower;
    uint256 startTime;
    uint256 endTime;
    uint256 executionTime;
    string link;
    bool executed;
    bool canceled;
  }

  struct Proposal {
    ProposalWithoutVote proposalData;
    mapping(address => Vote) votes;
  }

  struct BinaryProposalParams {
    address[] targets;
    uint256[] weiValues;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
  }

  /**
   * @dev emitted when a new binary proposal is created
   * @param proposalId id of the binary proposal
   * @param creator address of the creator
   * @param executor ExecutorWithTimelock contract that will execute the proposal
   * @param strategy votingPowerStrategy contract to calculate voting power
   * @param targets list of contracts called by proposal's associated transactions
   * @param weiValues list of value in wei for each propoposal's associated transaction
   * @param signatures list of function signatures (can be empty) to be used
   *     when created the callData
   * @param calldatas list of calldatas: if associated signature empty,
   *     calldata ready, else calldata is arguments
   * @param withDelegatecalls boolean, true = transaction delegatecalls the taget,
   *    else calls the target
   * @param startTime timestamp when vote starts
   * @param endTime timestamp when vote ends
   * @param link URL link of the proposal
   * @param maxVotingPower max voting power for this proposal
   **/
  event BinaryProposalCreated(
    uint256 proposalId,
    address indexed creator,
    IExecutorWithTimelock indexed executor,
    IVotingPowerStrategy indexed strategy,
    address[] targets,
    uint256[] weiValues,
    string[] signatures,
    bytes[] calldatas,
    bool[] withDelegatecalls,
    uint256 startTime,
    uint256 endTime,
    string link,
    uint256 maxVotingPower
  );

  /**
   * @dev emitted when a new generic proposal is created
   * @param proposalId id of the generic proposal
   * @param creator address of the creator
   * @param executor ExecutorWithTimelock contract that will execute the proposal
   * @param strategy votingPowerStrategy contract to calculate voting power
   * @param options list of proposal vote options
   * @param startTime timestamp when vote starts
   * @param endTime timestamp when vote ends
   * @param link URL link of the proposal
   * @param maxVotingPower max voting power for this proposal
   **/
  event GenericProposalCreated(
    uint256 proposalId,
    address indexed creator,
    IExecutorWithTimelock indexed executor,
    IVotingPowerStrategy indexed strategy,
    string[] options,
    uint256 startTime,
    uint256 endTime,
    string link,
    uint256 maxVotingPower
  );

  /**
   * @dev emitted when a proposal is canceled
   * @param proposalId id of the proposal
   **/
  event ProposalCanceled(uint256 proposalId);

  /**
   * @dev emitted when a proposal is queued
   * @param proposalId id of the proposal
   * @param executionTime time when proposal underlying transactions can be executed
   * @param initiatorQueueing address of the initiator of the queuing transaction
   **/
  event ProposalQueued(
    uint256 indexed proposalId,
    uint256 executionTime,
    address indexed initiatorQueueing
  );
  /**
   * @dev emitted when a proposal is executed
   * @param proposalId id of the proposal
   * @param initiatorExecution address of the initiator of the execution transaction
   **/
  event ProposalExecuted(uint256 proposalId, address indexed initiatorExecution);
  /**
   * @dev emitted when a vote is registered
   * @param proposalId id of the proposal
   * @param voter address of the voter
   * @param voteOptions vote options selected by voter
   * @param votingPower Power of the voter/vote
   **/
  event VoteEmitted(
    uint256 indexed proposalId,
    address indexed voter,
    uint32 indexed voteOptions,
    uint224 votingPower
  );

  /**
   * @dev emitted when a vote is registered
   * @param proposalId id of the proposal
   * @param voter address of the voter
   * @param voteOptions vote options selected by voter
   * @param oldVotingPower Old power of the voter/vote
   * @param newVotingPower New power of the voter/vote
   **/
  event VotingPowerChanged(
    uint256 indexed proposalId,
    address indexed voter,
    uint32 indexed voteOptions,
    uint224 oldVotingPower,
    uint224 newVotingPower
  );

  event DaoOperatorTransferred(address indexed newDaoOperator);

  event ExecutorAuthorized(address indexed executor);

  event ExecutorUnauthorized(address indexed executor);

  event VotingPowerStrategyAuthorized(address indexed strategy);

  event VotingPowerStrategyUnauthorized(address indexed strategy);

  /**
   * @dev Function is triggered when users withdraw from staking and change voting power
   */
  function handleVotingPowerChanged(
    address staker,
    uint256 newVotingPower,
    uint256[] calldata proposalIds
  ) external;

  /**
   * @dev Creates a Binary Proposal (needs to be validated by the Proposal Validator)
   * @param executor The ExecutorWithTimelock contract that will execute the proposal
   * @param strategy voting power strategy of the proposal
   * @param executionParams data for execution, includes
   *   targets list of contracts called by proposal's associated transactions
   *   weiValues list of value in wei for each proposal's associated transaction
   *   signatures list of function signatures (can be empty)
   *        to be used when created the callData
   *   calldatas list of calldatas: if associated signature empty,
   *        calldata ready, else calldata is arguments
   *   withDelegatecalls boolean, true = transaction delegatecalls the taget,
   *        else calls the target
   * @param startTime start timestamp to allow vote
   * @param endTime end timestamp of the proposal
   * @param link link to the proposal description
   **/
  function createBinaryProposal(
    IExecutorWithTimelock executor,
    IVotingPowerStrategy strategy,
    BinaryProposalParams memory executionParams,
    uint256 startTime,
    uint256 endTime,
    string memory link
  ) external returns (uint256 proposalId);

  /**
   * @dev Creates a Generic Proposal
   * @param executor ExecutorWithTimelock contract that will execute the proposal
   * @param strategy votingPowerStrategy contract to calculate voting power
   * @param options list of proposal vote options
   * @param startTime timestamp when vote starts
   * @param endTime timestamp when vote ends
   * @param link URL link of the proposal
   **/
  function createGenericProposal(
    IExecutorWithTimelock executor,
    IVotingPowerStrategy strategy,
    string[] memory options,
    uint256 startTime,
    uint256 endTime,
    string memory link
  ) external returns (uint256 proposalId);

  /**
   * @dev Cancels a Proposal,
   * either at anytime by guardian
   * or when proposal is Pending/Active and threshold no longer reached
   * @param proposalId id of the proposal
   **/
  function cancel(uint256 proposalId) external;

  /**
   * @dev Queue the proposal (If Proposal Succeeded)
   * @param proposalId id of the proposal to queue
   **/
  function queue(uint256 proposalId) external;

  /**
   * @dev Execute the proposal (If Proposal Queued)
   * @param proposalId id of the proposal to execute
   **/
  function execute(uint256 proposalId) external payable;

  /**
   * @dev Function allowing msg.sender to vote for/against a proposal
   * @param proposalId id of the proposal
   * @param optionBitMask vote option(s) selected
   **/
  function submitVote(uint256 proposalId, uint256 optionBitMask) external;

  /**
   * @dev Function to register the vote of user that has voted offchain via signature
   * @param proposalId id of the proposal
   * @param choice the bit mask of voted options
   * @param v v part of the voter signature
   * @param r r part of the voter signature
   * @param s s part of the voter signature
   **/
  function submitVoteBySignature(
    uint256 proposalId,
    uint256 choice,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Add new addresses to the list of authorized executors
   * @param executors list of new addresses to be authorized executors
   **/
  function authorizeExecutors(address[] calldata executors) external;

  /**
   * @dev Remove addresses to the list of authorized executors
   * @param executors list of addresses to be removed as authorized executors
   **/
  function unauthorizeExecutors(address[] calldata executors) external;

  /**
   * @dev Add new addresses to the list of authorized strategies
   * @param strategies list of new addresses to be authorized strategies
   **/
  function authorizeVotingPowerStrategies(address[] calldata strategies) external;

  /**
   * @dev Remove addresses to the list of authorized strategies
   * @param strategies list of addresses to be removed as authorized strategies
   **/
  function unauthorizeVotingPowerStrategies(address[] calldata strategies) external;

  /**
   * @dev Returns whether an address is an authorized executor
   * @param executor address to evaluate as authorized executor
   * @return true if authorized
   **/
  function isExecutorAuthorized(address executor) external view returns (bool);

  /**
   * @dev Returns whether an address is an authorized strategy
   * @param strategy address to evaluate as authorized strategy
   * @return true if authorized
   **/
  function isVotingPowerStrategyAuthorized(address strategy) external view returns (bool);

  /**
   * @dev Getter the address of the guardian, that can mainly cancel proposals
   * @return The address of the guardian
   **/
  function getDaoOperator() external view returns (address);

  /**
   * @dev Getter of the proposal count (the current number of proposals ever created)
   * @return the proposal count
   **/
  function getProposalsCount() external view returns (uint256);

  /**
   * @dev Getter of a proposal by id
   * @param proposalId id of the proposal to get
   * @return the proposal as ProposalWithoutVote memory object
   **/
  function getProposalById(uint256 proposalId) external view returns (ProposalWithoutVote memory);

  /**
   * @dev Getter of the vote data of a proposal by id
   * including totalVotes, voteCounts and options
   * @param proposalId id of the proposal
   * @return (totalVotes, voteCounts, options)
   **/
  function getProposalVoteDataById(uint256 proposalId)
    external
    view
    returns (
      uint256,
      uint256[] memory,
      string[] memory
    );

  /**
   * @dev Getter of the Vote of a voter about a proposal
   * Note: Vote is a struct: ({uint32 bitOptionMask, uint224 votingPower})
   * @param proposalId id of the proposal
   * @param voter address of the voter
   * @return The associated Vote memory object
   **/
  function getVoteOnProposal(uint256 proposalId, address voter)
    external
    view
    returns (Vote memory);

  /**
   * @dev Get the current state of a proposal
   * @param proposalId id of the proposal
   * @return The current state if the proposal
   **/
  function getProposalState(uint256 proposalId) external view returns (ProposalState);
}