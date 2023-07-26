/// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title IAuctionHouse
/// @dev Interface for the AuctionHouse
interface IAuctionHouse {
    struct Auction {
        address tokenHolder;
        address payable beneficiary;
        address token;
        uint256 tokenId;
        uint256 tokenAmount;
        uint256 startAt;
        uint256 endAt;
        bool ended;
        address highestBidder;
        uint256 highestBid;
    }

    event AuctionCreated(address indexed seller, uint256 indexed auctionId);
    event AuctionItemClaimed(
        address indexed winner,
        address indexed token,
        uint256 indexed tokenId,
        uint256 tokenAmount,
        uint256 winningBid
    );
    event Bid(
        address indexed seller,
        uint256 indexed auctionIndex,
        address indexed bidder,
        uint256 amount,
        uint256 timestamp
    );
    event MinBidIncrementSet(uint256 oldMinBidIncrement, uint256 newMinBidIncrement);

    function createAuction(
        address tokenHolder,
        address payable beneficiary,
        address token,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 startAt,
        uint256 endAt,
        uint256 startingBid
    ) external;

    function bid(address seller, uint256 auctionIndex) external payable;

    function claim(address seller, uint256 auctionId) external;

    function auctionAt(address seller, uint256 index) external view returns (Auction memory);

    function auctionCount(address seller) external view returns (uint256);

    function setMinBidIncrement(uint256 newMinBidIncrement) external;
}