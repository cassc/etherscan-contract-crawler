// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import { Module } from "src/module/Module.sol";
import { ModuleConfig } from "src/module/governance-pool/ModuleConfig.sol";

/// GovernancePool Wraps governance pool module functionality
interface GovernancePool is Module {
  error InitExternalDAONotSet();
  error InitExternalTokenNotSet();
  error InitFeeRecipientNotSet();
  error InitCastWindowNotSet();
  error InitBaseWalletNotSet();

  error BidTooLow();
  error BidAuctionEnded();
  error BidInvalidSupport();
  error BidReserveNotMet();
  error BidProposalNotActive();
  error BidVoteAlreadyCast();
  error BidMaxBidExceeded();
  error BidModulePaused();

  error CastVoteBidDoesNotExist();
  error CastVoteNotInWindow();
  error CastVoteNoDelegations();
  error CastVoteMustWait();
  error CastVoteAlreadyCast();

  error ClaimOnlyBidder();
  error ClaimAlreadyRefunded();
  error ClaimNotRefundable();

  error WithdrawDelegateOrOwnerOnly();
  error WithdrawBidNotOffered();
  error WithdrawBidRefunded();
  error WithdrawVoteNotCast();
  error WithdrawPropIsActive();
  error WithdrawAlreadyClaimed();
  error WithdrawInvalidProof(string);
  error WithdrawNoBalanceAtPropStart();
  error WithdrawNoTokensDelegated();
  error WithdrawMaxProverVersion();

  /// Bid is the structure of an offer to cast a vote on a proposal
  struct Bid {
    /// The amount of ETH bid
    uint256 amount;
    /// The remaining amount of ETH left to be withdrawn
    uint256 remainingAmount;
    /// The remaining amount of votes left to withdraw proceeds from the pool
    uint256 remainingVotes;
    /// The block number the external proposal was created
    uint256 creationBlock;
    /// The block number the external proposal voting period started
    uint256 startBlock;
    /// The block number the external proposal voting period ends
    uint256 endBlock;
    /// the block number the bid was made
    uint256 bidBlock;
    /// The support value to cast if this bid wins
    uint256 support;
    /// The address of the bidder
    address bidder;
    /// Whether the vote was cast for this bid
    bool executed;
    /// Whether the bid was refunded
    bool refunded;
  }

  /// Emitted when a vote has been cast against an external proposal
  event VoteCast(
    address indexed dao, uint256 indexed propId, uint256 support, uint256 amount, address bidder
  );

  /// Emitted when a bid has been placed
  event BidPlaced(
    address indexed dao, uint256 indexed propId, uint256 support, uint256 amount, address bidder
  );

  /// Emitted when a refund has been claimed
  event RefundClaimed(
    address indexed dao, uint256 indexed propId, uint256 amount, address receiver
  );

  /// Emitted when proceeds have been withdrawn for a proposal
  event Withdraw(address indexed dao, address indexed receiver, uint256[] propId, uint256 amount);

  /// Emitted when a protocol fee has been applied when casting votes
  event ProtocolFeeApplied(address indexed recipient, uint256 amount);

  /// Bid on a proposal
  function bid(uint256, uint256) external payable;

  /// Cast a vote from the contract to external proposal
  function castVote(uint256) external;

  /// Claim a refund for a bid where the vote was not cast
  function claimRefund(uint256) external;

  /// Withdraw proceeds in proportion of delegation from a bid where the vote was cast
  /// A max of 5 props can be withdrawn from at once
  function withdraw(
    address _prover,
    address _delegator,
    uint256[] calldata _pId,
    uint256[] calldata _fee,
    bytes[] calldata _proof
  ) external payable returns (uint256);

  /// Get the bid for a proposal
  function getBid(uint256 _pId) external view returns (Bid memory);

  /// Returns whether an account has made a withdrawal for a proposal
  function withdrawn(uint256 _pId, address _account) external view returns (bool);

  /// Returns the next minimum bid amount for a proposal
  function minBidAmount(uint256 _pid) external view returns (uint256);
}