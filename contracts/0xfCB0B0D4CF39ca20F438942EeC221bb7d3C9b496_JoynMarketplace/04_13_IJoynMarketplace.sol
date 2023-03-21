// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IJoynMarketplace {
    struct Listing {
        uint256 listingId;
        uint256 price;
        uint256 marketplaceFeeAmount;
        uint32 marketplaceFee;
        address seller;
        address buyer;
    }

    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 listingId,
        uint256 price,
        uint256 marketplaceFee
    );

    event ListingUpdated(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 listingId,
        uint256 price,
        uint256 marketplaceFee
    );

    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 listingId
    );

    event ItemBought(
        address seller,
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 listingId,
        uint256 price,
        uint256 amountTransferredToSeller,
        uint256 marketplaceFeeAmount
    );

    event RoyaltyTransfered(
        address recipient,
        uint256 amount,
        uint256 tokenId,
        address tokenAddress,
        uint256 listingId
    );

    event ReferrerFeeTransferred(
        address recipient,
        uint256 amount,
        uint256 tokenId,
        address tokenAddress,
        uint256 listingId
    );
}