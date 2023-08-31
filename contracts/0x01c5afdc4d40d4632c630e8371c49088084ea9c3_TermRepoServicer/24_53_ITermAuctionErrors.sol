//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @title ITermAuctionErrors defines all errors emitted by the Term Auction
interface ITermAuctionErrors {
    /// Term contracts have already been paired.
    error AlreadyTermContractPaired();

    /// Error emmitted when completing an auction that has already been completed
    error AuctionAlreadyCompleted();

    /// Error emmitted when completing an auction that has been cancelled for withdrawal
    error AuctionCancelledForWithdrawal();

    /// Error emmitted when the auction is not closed, but must be
    error AuctionNotClosed();

    /// Error emitted when the provided clearingOffset is not 0 or 1
    error ClearingOffsetNot0Or1(uint256 clearingOffset);

    /// Complete Auction has been paused.
    error CompleteAuctionPaused();

    /// Invalid Parameters passed into function
    error InvalidParameters(string message);

    /// Error emitted when the maximum binary search depth has been exceeded
    error MaxPriceSearchDepthExceeded(uint256 maxDepth);

    /// Error emitted when there are no bids or offers
    error NoBidsOrOffers();
}