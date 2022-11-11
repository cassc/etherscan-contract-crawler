// SPDX-License-Identifier: MIT

/// @title Interface for Sweeper Auction Houses



pragma solidity ^0.8.6;

interface ISweepersAuctionHouse {
    struct Auction {
        // ID for the Sweeper (ERC721 token ID)
        uint256 sweeperId;
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

    struct Bids {
        address payable bidder;
        uint256 amount;
        uint256 bidTime;
    }

    event AuctionCreated(uint256 indexed sweeperId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 indexed sweeperId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed sweeperId, uint256 endTime);

    event AuctionSettled(uint256 indexed sweeperId, address winner, uint256 amount, bool sniped);

    event AuctionSniped(uint256 indexed sweeperId, address sniper, address originalWinner, uint256 snipedAmount, uint256 winningAmount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    function auctionInfo() external view returns (uint256, uint256, address, bool);

    function settleAuction() external payable;

    function settleCurrentAndCreateNewAuction() external payable;

    function createBid(uint256 sweeperId) external payable;

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setDuration(uint256 _duration) external;

    function setSettlementTimeInterval(uint256 _winnerSettlementTime, uint256 _settlementTimeinterval) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;

    function setSweepersDev(address _sweepersDev) external;

    function setSweepersSettler(address _address) external;

    function setSweepersTreasury(address _sweepersTreasury) external;

    function setMetatopiaTreasury(address _metatopiaTreasury) external;

    function setMetatopiaPercent(uint16 _metatopiaPercent) external;
}