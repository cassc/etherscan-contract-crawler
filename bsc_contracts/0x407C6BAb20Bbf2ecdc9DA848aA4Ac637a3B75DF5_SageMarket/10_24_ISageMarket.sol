// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/**
 * @title ISageMarket
 * @author Dallenogare Corentin
 */
interface ISageMarket {
    /**
     * @notice Emits when a item is successfully put on sale.
     */
    event CreateMarketItem (
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        uint256 price,
        bool onSale,
        uint256 amount,
        uint8 tokenType
    );

    /**
     * @notice Emits when someone buy the nft.
     */
    event CreateMarketSale (
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 price,
        bool onSale,
        uint256 fee,
        uint256 amount
    );

    /**
     * @notice Emits when a market item is successfully cancelled and nft are transferred back.
     */
    event CancelMarketItem(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        bool onSale
    );

    
}