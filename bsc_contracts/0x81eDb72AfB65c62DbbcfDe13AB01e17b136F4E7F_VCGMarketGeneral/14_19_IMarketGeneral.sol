// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMarketGeneral {
    enum Side {
        Sell,
        Bid
    }

    enum CollectionType {
        ERC721,
        ERC1155
    }

    enum OfferStatus {
        NotExist,
        Open,
        Accepted,
        Cancelled
    }

    enum OfferStrategy {
        FixedPrice,
        Auction
    }

    struct Offer {
        Side side;
        address maker; // signer of the maker order
        address collection; // collection address
        CollectionType collectionType; // collection type 721 / 1155
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        uint256 price; // price
        OfferStrategy strategy; // strategy for trade execution (e.g., Auction, StandardSaleForFixedPrice)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        OfferStatus status;
    }

    struct AuctionInfo {
        bool buyOut; // check buyout for auction
        address auctionCurrency; // auction for currency only
    }

    struct BidInfo {
        address bidCurrency; // for bid only
    }

    struct TransferHandler {
        Offer offer;
        address seller;
        address buyer;
        uint256 paymentFee;
        uint256 payment;
        uint256 nftAmount;
        address currencyAddress;
    }
}