//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Dutch Auction Interface
/// @dev Defines the methods and structures for the Dutch Auction contract.
interface IDutchAuction {
  /// Errors
  /// @dev Emitted when trying to interact with the contract before its config is set.
  error ConfigNotSet();

  /// @dev Emitted when trying to set the contract config when it's already been set.
  error ConfigAlreadySet();

  /// @dev Emitted when the amount of wei provided is invalid.
  error InvalidAmountInWei();

  /// @dev Emitted when the start or end time is invalid.
  error InvalidStartEndTime(uint64 startTime, uint64 endTime);

  /// @dev Emitted when the quantity provided is invalid.
  error InvalidQuantity();

  /// @dev Emitted when trying to interact with the contract before the auction has ended.
  error NotEnded();

  /// @dev Emitted when the value provided is not enough for the desired action.
  error NotEnoughValue();

  /// @dev Emitted when trying to request a refund when not eligible.
  error NotRefundable();

  /// @dev Emitted when trying to interact with the contract before the auction has started.
  error NotStarted();

  /// @dev Emitted when a transfer fails.
  error TransferFailed();

  /// @dev Emitted when a user tries to claim a refund that they've already claimed.
  error UserAlreadyClaimed();

  /// @dev Emitted when a bid has expired.
  error BidExpired(uint256 deadline);

  /// @dev Emitted when the provided signature is invalid.
  error InvalidSignature();

  /// @dev Emitted when the purchase limit is reached.
  error PurchaseLimitReached();

  /// @dev Emitted when trying to claim a refund before the refund time is ready.
  error ClaimRefundNotReady();

  /// @dev Emitted when there's nothing to claim.
  error NothingToClaim();

  /// @dev Emitted when funds have already been withdrawn.
  error AlreadyWithdrawn();

  /// @dev Emitted when the max supply is reached.
  error MaxSupplyReached();

  /// @dev Emitted when the proof length is invalid when claiming users refunds.
  error InvalidProofsLength();

  /// @dev Represents a user in the auction

  struct User {
    /// @notice The total amount of ETH contributed by the user.
    uint216 contribution;
    /// @notice The total number of tokens bidded by the user.
    uint32 tokensBidded;
    /// @notice A flag indicating if the user has claimed a refund.
    bool refundClaimed;
  }

  /// @dev Represents the auction configuration
  struct Config {
    /// @notice The initial amount per token in wei when the auction starts.
    uint256 startAmountInWei;
    /// @notice The final amount per token in wei when the auction ends.
    uint256 endAmountInWei;
    /// @notice The maximum contribution allowed per user in wei.
    uint216 limitInWei;
    /// @notice The delay time for a refund to be available.
    uint32 refundDelayTime;
    /// @notice The start time of the auction.
    uint64 startTime;
    /// @notice The end time of the auction.
    uint64 endTime;
  }
  /// @dev Emitted when a user claims a refund.
  /// @param user The address of the user claiming the refund.
  /// @param refundInWei The amount of the refund in Wei.
  event ClaimRefund(address user, uint256 refundInWei);

  /// @dev Emitted when a user places a bid.
  /// @param user The address of the user placing the bid.
  /// @param qty The quantity of tokens the user is bidding for.
  /// @param price The total price of the bid in Wei.
  event Bid(address user, uint32 qty, uint256 price);

  /// @dev Emitted when a user claims their tokens after the auction.
  /// @param user The address of the user claiming the tokens.
  /// @param qty The quantity of tokens claimed.
  event Claim(address user, uint32 qty);
}