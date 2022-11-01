// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Auction Houses

pragma solidity ^0.8.17;

interface IAuctionHouse {
    struct Auction {
        // ID for the VesselVerse (ERC721 token ID)
        uint256 vesselverseId;
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
        uint256 indexed vesselverseId,
        uint256 startTime,
        uint256 endTime
    );

    event AuctionBid(
        uint256 indexed vesselverseId,
        address sender,
        uint256 value,
        bool extended
    );

    event AuctionExtended(uint256 indexed vesselverseId, uint256 endTime);

    event AuctionSettled(
        uint256 indexed vesselverseId,
        address winner,
        uint256 amount
    );

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(
        uint256 minBidIncrementPercentage
    );

    function settleAuction() external;

    function settleCurrentAndCreateNewAuction() external;

    function createBid(uint256 vesselverseId) external payable;

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage)
        external;
}