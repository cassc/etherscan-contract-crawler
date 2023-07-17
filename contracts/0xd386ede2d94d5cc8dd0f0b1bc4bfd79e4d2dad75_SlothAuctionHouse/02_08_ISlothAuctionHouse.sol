// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

/**
 * @title Interface for Auction Houses
 */
interface ISlothAuctionHouse {
    struct Auction {
        // ID for the ERC721 token
        uint256 tokenId;
        address tokenOwner;
        // Address for the ERC721 contract
        address tokenContract;
        // The current highest bid amount
        uint256 amount;
        // The length of time to run the auction for, after the first bid was made
        uint256 timeBuffer;
        // The minimum price of the first bid
        uint256 reservePrice;
        uint8 minBidIncrementPercentage;
        // The address of the current highest bid
        address payable bidder;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // Whether or not the auction has been settled
        bool settled;
    }

    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 tokenId,
        address tokenOwner,
        address indexed tokenContract,
        uint256 startTime,
        uint256 endTime
    );

    event AuctionBid(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address sender,
        uint256 value,
        bool extended
    );

    event AuctionExtended(
        uint256 indexed auctionId,
        uint256 endTime
    );

    event AuctionCanceled(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract
    );

    event AuctionSettled(
      uint256 indexed auctionId,
      address bidder,
      uint256 amount
    );

    function createAuction(
        uint256 tokenId,
        address tokenContract,
        uint256 startTime,
        uint256 endTime
    ) external returns (uint256);

    function createBid(uint256 auctionId, uint256 amount) external payable;

    function cancelAuction(uint256 auctionId) external;
}