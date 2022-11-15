// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMarketplace {
    event Bids(uint256 indexed itemId, address bidder, uint256 amount);
    event Sales(uint256 indexed itemId, address indexed owner, uint256 amount, uint256 quantity, uint256 indexed tokenId);
    event Closes(uint256 indexed itemId);
    event Listings(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address receiver,
        address owner,
        uint256 price,
        bool sold
    );
    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address seller;
        address owner;
        uint256 price;
        uint256 quantity;
        bool sold;
        address receiver;
    }
}