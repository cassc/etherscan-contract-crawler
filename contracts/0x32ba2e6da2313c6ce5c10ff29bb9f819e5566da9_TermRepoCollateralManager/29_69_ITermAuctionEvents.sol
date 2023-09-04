//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @title ITermAuctionEvents defines all events emitted by the TermAuctionContract.
interface ITermAuctionEvents {
    /// Event emitted when a new auction is initialized
    /// @param termRepoId The term ID
    /// @param termAuctionId The term auction Id
    /// @param termAuction auction contract address
    /// @param auctionEndTime The auction end time
    /// @param version The version tag of the smart contract deployed
    event TermAuctionInitialized(
        bytes32 termRepoId,
        bytes32 termAuctionId,
        address termAuction,
        uint256 auctionEndTime,
        string version
    );

    /// Event emitted when a bid is assigned
    /// @param termAuctionId The auction ID
    /// @param id The bid ID
    /// @param amount The amount assigned
    event BidAssigned(bytes32 termAuctionId, bytes32 id, uint256 amount);

    /// Event emitted when an offer is assigned
    /// @param termAuctionId The term ID
    /// @param id The offer ID
    /// @param amount The amount assigned
    event OfferAssigned(bytes32 termAuctionId, bytes32 id, uint256 amount);

    /// Event emitted when an auction is completed
    /// @param termAuctionId The ID of the auction
    /// @param timestamp The timestamp of the auction completion
    /// @param block The block of the auction completion
    /// @param totalAssignedBids The total amount of bids assigned
    /// @param totalAssignedOffers The total amount of offers assigned
    /// @param clearingPrice The clearing price of the auction
    event AuctionCompleted(
        bytes32 termAuctionId,
        uint256 timestamp,
        uint256 block,
        uint256 totalAssignedBids,
        uint256 totalAssignedOffers,
        uint256 clearingPrice
    );

    /// Event emitted when an auction is cancelled.
    /// @param termAuctionId The ID of the auction.
    /// @param nonViableAuction Auction not viable due to bid and offer prices not intersecting
    /// @param auctionCancelledforWithdrawal Auction has been cancelled for manual fund withdrawal
    event AuctionCancelled(
        bytes32 termAuctionId,
        bool nonViableAuction,
        bool auctionCancelledforWithdrawal
    );

    /// Event emitted when an auction is paused.
    /// @param termAuctionId The ID of the auction.
    /// @param termRepoId The ID of the repo.
    event CompleteAuctionPaused(bytes32 termAuctionId, bytes32 termRepoId);

    /// Event emitted when an auction is unpaused.
    /// @param termAuctionId The ID of the auction.
    /// @param termRepoId The ID of the repo.
    event CompleteAuctionUnpaused(bytes32 termAuctionId, bytes32 termRepoId);
}