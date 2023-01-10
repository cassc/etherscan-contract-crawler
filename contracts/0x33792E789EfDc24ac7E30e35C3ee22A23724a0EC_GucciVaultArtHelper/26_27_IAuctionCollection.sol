// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IAuctionCollection {
    struct Auction {
        // Token URI for auction
        string tokenURI;
        // Address that should receive the funds
        address creator;
        // Reserve price
        uint256 reservePrice;
        // The length of time to run the auction for
        uint256 duration;
        // Current highest bid amount
        uint256 amount;
        // Address of the highest bidder
        address bidder;
        // Auction is active
        bool active;
        // Auction started time
        uint256 startedAt;
    }

    event AuctionCreated(uint256 indexed auctionId, address indexed creator);

    event AuctionBidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount
    );

    event AuctionActive(uint256 indexed auctionId, bool indexed active);

    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 amount
    );
}