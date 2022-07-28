// SPDX-License-Identifier: GPL-3.0
/********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░██████████████████████░░░ *
 * ░░░██░░░░░░██░░░░░░████░░░░░ *
 * ░░░██░░░░░░██░░░░░░██░░░░░░░ *
 * ░░░██████████████████░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 ************************♥tt****/
pragma solidity ^0.8.15;

interface IPhunksAuctionHouse {
    struct Auction {
        // ID for the Phunk (ERC721 token ID)
        uint phunkId;
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
        // Auction ID number
        uint256 auctionId;
    }

    event AuctionCreated(uint indexed phunkId, uint256 auctionId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint indexed phunkId, uint256 auctionId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint indexed phunkId, uint256 auctionId, uint256 endTime);

    event AuctionSettled(uint indexed phunkId, uint256 auctionId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionDurationUpdated(uint256 duration);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    function settleAuction() external;

    function settleCurrentAndCreateNewAuction() external;

    function createBid(uint phunkId) external payable;

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setDuration(uint256 duration) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;
}