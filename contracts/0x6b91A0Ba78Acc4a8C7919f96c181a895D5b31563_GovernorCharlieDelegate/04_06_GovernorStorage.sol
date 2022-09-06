// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IIpt.sol";
import "./Structs.sol";

contract GovernorCharlieDelegatorStorage {
  /// @notice Active brains of Governor
  address public implementation;
}

/**
 * @title Storage for Governor Charlie Delegate
 * @notice For future upgrades, do not change GovernorCharlieDelegateStorage. Create a new
 * contract which implements GovernorCharlieDelegateStorage and following the naming convention
 * GovernorCharlieDelegateStorageVX.
 */
//solhint-disable-next-line max-states-count
contract GovernorCharlieDelegateStorage is GovernorCharlieDelegatorStorage {
  /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
  uint256 public quorumVotes;

  /// @notice The number of votes in support of a proposal required in order for an emergency quorum to be reached and for a vote to succeed
  uint256 public emergencyQuorumVotes;

  /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
  uint256 public votingDelay;

  /// @notice The duration of voting on a proposal, in blocks
  uint256 public votingPeriod;

  /// @notice The number of votes required in order for a voter to become a proposer
  uint256 public proposalThreshold;

  /// @notice Initial proposal id set at become
  uint256 public initialProposalId;

  /// @notice The total number of proposals
  uint256 public proposalCount;

  /// @notice The address of the Interest Protocol governance token
  IIpt public ipt;

  /// @notice The official record of all proposals ever proposed
  mapping(uint256 => Proposal) public proposals;

  /// @notice The latest proposal for each proposer
  mapping(address => uint256) public latestProposalIds;

  /// @notice The latest proposal for each proposer
  mapping(bytes32 => bool) public queuedTransactions;

  /// @notice The proposal holding period
  uint256 public proposalTimelockDelay;

  /// @notice Stores the expiration of account whitelist status as a timestamp
  mapping(address => uint256) public whitelistAccountExpirations;

  /// @notice Address which manages whitelisted proposals and whitelist accounts
  address public whitelistGuardian;

  /// @notice The duration of the voting on a emergency proposal, in blocks
  uint256 public emergencyVotingPeriod;

  /// @notice The emergency proposal holding period
  uint256 public emergencyTimelockDelay;

  /// all receipts for proposal
  mapping(uint256 => mapping(address => Receipt)) public proposalReceipts;

  /// @notice The emergency proposal holding period
  bool public initialized;

  /// @notice The number of votes to reject an optimistic proposal
  uint256 public optimisticQuorumVotes; 

  /// @notice The delay period before voting begins
  uint256 public optimisticVotingDelay; 

  /// @notice The maximum number of seconds an address can be whitelisted for
  uint256 public maxWhitelistPeriod; 
}