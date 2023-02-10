// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Auction Houses

pragma solidity ^0.8.6;

import { CommonSpaces } from "./CommonSpaces.sol";

interface IAuctionHouse {

    struct Auction {
        // ID for the (ERC721 token ID)
        uint256 tokenId;
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
        // amount of time auction was extended
        uint256 extendedTime;
    }


    event AuctionBid(address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed tokenId, uint256 endTime);

    event AuctionSettled(uint256 indexed tokenId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    event AuctionDurationUpdated(uint256 duration);

    event AllowlistMint(address indexed to);

    function setAuctionWinners(address[] memory _auctionWinners, uint256[] memory _price) external;

    // function settleCurrentAndCreateNewAuction() external;

    //function settleAuction(uint256 tokenId) external;

    function setTimes(uint256 _startTime, uint256 _duration) external;

    

    function createBid() external payable;

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 timeBuffer) external;

    // function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;

    function setDuration(uint256 _duration) external;

}