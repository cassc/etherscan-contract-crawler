// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Auction Houses
/// Modified from INounsAuctionHouse

pragma solidity ^0.8.6;

interface ITransitionAuctionHouse {
    struct Auction {
        // ID for the Transition (ERC721 token ID)
        uint256 transitionId;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
    }

    event AuctionCreated(
        uint256 indexed transitionId,
        uint256 startTime,
        uint256 endTime
    );

    event AuctionBid(
        uint256 indexed transitionId,
        address sender,
        uint256 value,
        bool extended
    );

    event AuctionExtended(uint256 indexed transitionId, uint256 endTime);

    event AuctionSettled(
        uint256 indexed transitionId,
        address winner,
        uint256 amount
    );

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(
        uint256 minBidIncrementPercentage
    );

    function settleCurrentAndCreateNewAuction() external;

    function createBid(uint256 transitionId) external payable;
}