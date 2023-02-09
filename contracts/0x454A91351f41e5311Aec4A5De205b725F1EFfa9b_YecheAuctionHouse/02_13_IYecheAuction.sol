// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;  
pragma experimental ABIEncoderV2;

/**
 * @title Interface for Auction Houses
 */
interface IYecheAuctionHouse {
    // struct Bid {
    //     address payable bidder;
    //     uint256 amount;
    //     uint256 timestamp;
    // }

    struct Auction {
        // ID for the ERC721 token
        uint256 tokenId;
        // Address for the ERC721 contract
        address tokenContract;
        // Whether or not the auction contract owner has approved the auction to start
        bool approved;
        // The current highest bid amount
        uint256 amount;
        // The length of time to run the auction for, after the first bid was made
        uint256 duration;
        // The time of the first bid
        uint256 firstBidTime;
        // The minimum price of the first bid
        uint256 reservePrice;
        // The address that should receive the funds once the NFT is sold.
        address tokenOwner;
        // The address of the current highest bid
        address payable bidder;
        // The split address for this NFT.
        address payable splitAddress;
        // The address of the ERC-20 currency to run the auction with.
        // If set to 0x0, the auction will be run in ETH
        address auctionCurrency;

        // uint256 numBids;
        // mapping(uint256 => Bid) bidHistory;
    }

    struct Bid {
        address payable bidder;
        uint256 amount;
        uint256 timestamp;
    }

    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address tokenOwner,
        address splitAddress,
        address auctionCurrency
    );

    event AuctionApprovalUpdated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        bool approved
    );

    event AuctionReservePriceUpdated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 reservePrice
    );

    event AuctionBid(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address sender,
        uint256 value,
        bool firstBid,
        bool extended
    );

    event AuctionDurationExtended(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 duration
    );

    event AuctionEnded(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner,
        address splitAddress,
        address winner,
        uint256 amount,
        address auctionCurrency
    );

    event AuctionCanceled(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner
    );

    function createAuction(
        uint256 tokenId,
        address tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address payable splitAddress,
        address auctionCurrency
    ) external returns (uint256);

    function getBidHistory(uint256 auctionId) external view returns (Bid[] memory);

    function getUserBid(address user, uint256 minAuctionId, uint256 maxAuctionId) external view returns (bool);

    function setAuctionApproval(uint256 auctionId, bool approved) external;

    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice) external;

    function createBid(uint256 auctionId, uint256 amount) external payable;

    function endAuction(uint256 auctionId) external;

    function cancelAuction(uint256 auctionId) external;
}