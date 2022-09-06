// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Structs.sol";

/// @title interface to interact with TokenDelgator
interface IGovernorCharlieDelegator {
  function _setImplementation(address implementation_) external;

  fallback() external payable;

  receive() external payable;
}

/// @title interface to interact with TokenDelgate
interface IGovernorCharlieDelegate {
  function initialize(
    address ipt_
  ) external;

  function propose(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    string memory description,
    bool emergency
  ) external returns (uint256);

  function queue(uint256 proposalId) external;

  function execute(uint256 proposalId) external payable;

  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) external payable;

  function cancel(uint256 proposalId) external;

  function getActions(uint256 proposalId)
    external
    view
    returns (
      address[] memory targets,
      uint256[] memory values,
      string[] memory signatures,
      bytes[] memory calldatas
    );

  function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory);

  function state(uint256 proposalId) external view returns (ProposalState);

  function castVote(uint256 proposalId, uint8 support) external;

  function castVoteWithReason(
    uint256 proposalId,
    uint8 support,
    string calldata reason
  ) external;

  function castVoteBySig(
    uint256 proposalId,
    uint8 support,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function isWhitelisted(address account) external view returns (bool);

  function _setDelay(uint256 proposalTimelockDelay_) external;

  function _setEmergencyDelay(uint256 emergencyTimelockDelay_) external;

  function _setVotingDelay(uint256 newVotingDelay) external;

  function _setVotingPeriod(uint256 newVotingPeriod) external;

  function _setEmergencyVotingPeriod(uint256 newEmergencyVotingPeriod) external;

  function _setProposalThreshold(uint256 newProposalThreshold) external;

  function _setQuorumVotes(uint256 newQuorumVotes) external;

  function _setEmergencyQuorumVotes(uint256 newEmergencyQuorumVotes) external;

  function _setWhitelistAccountExpiration(address account, uint256 expiration) external;

  function _setWhitelistGuardian(address account) external;

  function _setOptimisticDelay(uint256 newOptimisticVotingDelay) external;

  function _setOptimisticQuorumVotes(uint256 newOptimisticQuorumVotes) external;
}

/// @title interface which contains all events emitted by delegator & delegate
interface GovernorCharlieEvents {
  /// @notice An event emitted when a new proposal is created
  event ProposalCreated(
    uint256 indexed id,
    address indexed proposer,
    address[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    uint256 indexed startBlock,
    uint256 endBlock,
    string description
  );

  /// @notice An event emitted when a vote has been cast on a proposal
  /// @param voter The address which casted a vote
  /// @param proposalId The proposal id which was voted on
  /// @param support Support value for the vote. 0=against, 1=for, 2=abstain
  /// @param votes Number of votes which were cast by the voter
  /// @param reason The reason given for the vote by the voter
  event VoteCast(address indexed voter, uint256 indexed proposalId, uint8 support, uint256 votes, string reason);

  /// @notice An event emitted when a proposal has been canceled
  event ProposalCanceled(uint256 indexed id);

  /// @notice An event emitted when a proposal has been queued in the Timelock
  event ProposalQueued(uint256 indexed id, uint256 eta);

  /// @notice An event emitted when a proposal has been executed in the Timelock
  event ProposalExecuted(uint256 indexed id);

  /// @notice An event emitted when the voting delay is set
  event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);

  /// @notice An event emitted when the voting period is set
  event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);

  /// @notice An event emitted when the emergency voting period is set
  event EmergencyVotingPeriodSet(uint256 oldEmergencyVotingPeriod, uint256 emergencyVotingPeriod);

  /// @notice Emitted when implementation is changed
  event NewImplementation(address oldImplementation, address newImplementation);

  /// @notice Emitted when proposal threshold is set
  event ProposalThresholdSet(uint256 oldProposalThreshold, uint256 newProposalThreshold);

  /// @notice Emitted when pendingAdmin is changed
  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

  /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
  event NewAdmin(address oldAdmin, address newAdmin);

  /// @notice Emitted when whitelist account expiration is set
  event WhitelistAccountExpirationSet(address account, uint256 expiration);

  /// @notice Emitted when the whitelistGuardian is set
  event WhitelistGuardianSet(address oldGuardian, address newGuardian);

  /// @notice Emitted when the a new delay is set
  event NewDelay(uint256 oldTimelockDelay, uint256 proposalTimelockDelay);

  /// @notice Emitted when the a new emergency delay is set
  event NewEmergencyDelay(uint256 oldEmergencyTimelockDelay, uint256 emergencyTimelockDelay);

  /// @notice Emitted when the quorum is updated
  event NewQuorum(uint256 oldQuorumVotes, uint256 quorumVotes);

  /// @notice Emitted when the emergency quorum is updated
  event NewEmergencyQuorum(uint256 oldEmergencyQuorumVotes, uint256 emergencyQuorumVotes);

  /// @notice An event emitted when the optimistic voting delay is set
  event OptimisticVotingDelaySet(uint256 oldOptimisticVotingDelay, uint256 optimisticVotingDelay);

  /// @notice Emitted when the optimistic quorum is updated
  event OptimisticQuorumVotesSet(uint256 oldOptimisticQuorumVotes, uint256 optimisticQuorumVotes);

  /// @notice Emitted when a transaction is canceled
  event CancelTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );

  /// @notice Emitted when a transaction is executed
  event ExecuteTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );

  /// @notice Emitted when a transaction is queued
  event QueueTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
}