// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IChainlinkPriceFeeds.sol";

library MediaEyeOrders {
    enum NftTokenType {
        ERC1155,
        ERC721
    }

    enum SubscriptionTier {
        Unsubscribed,
        LevelOne,
        LevelTwo
    }

    struct SubscriptionSignature {
        bool isValid;
        UserSubscription userSubscription;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct UserSubscription {
        address userAddress;
        MediaEyeOrders.SubscriptionTier subscriptionTier;
        uint256 startTime;
        uint256 endTime;
    }

    struct Listing {
        uint256 listingId;
        Nft[] nfts;
        address payable seller;
        uint256 timestamp;
        Split split;
    }

    struct Chainlink {
        address tokenAddress;
        uint256 tokenDecimals;
        address nativeAddress;
        uint256 nativeDecimals;
        IChainlinkPriceFeeds priceFeed;
        bool invertedAggregator;
    }

    struct AuctionConstructor {
        address _owner;
        address[] _admins;
        address payable _treasuryWallet;
        uint256 _basisPointFee;
        address _feeContract;
        address _mediaEyeMarketplaceInfo;
        address _mediaEyeCharities;
        Chainlink _chainlink;
    }

    struct OfferConstructor {
        address _owner;
        address[] _admins;
        address payable _treasuryWallet;
        uint256 _basisPointFee;
        address _feeContract;
        address _mediaEyeMarketplaceInfo;
    }

    struct AuctionAdmin {
        address payable _newTreasuryWallet;
        address _newFeeContract;
        address _newCharityContract;
        MediaEyeOrders.Chainlink _chainlink;
        uint256 _basisPointFee;
        bool _check;
        address _newInfoContract;
    }

    struct OfferAdmin {
        address payable _newTreasuryWallet;
        address _newFeeContract;
        uint256 _basisPointFee;
        address _newInfoContract;
    }

    struct AuctionInput {
        MediaEyeOrders.Nft[] nfts;
        MediaEyeOrders.AuctionPayment[] auctionPayments;
        MediaEyeOrders.PaymentChainlink chainlinkPayment;
        uint8 setRoyalty;
        uint256 royalty;
        MediaEyeOrders.Split split;
        AuctionTime auctionTime;
        MediaEyeOrders.SubscriptionSignature subscriptionSignature;
        MediaEyeOrders.Feature feature;
        string data;
    }

    struct AuctionTime {
        uint256 startTime;
        uint256 endTime;
    }

    struct Auction {
        uint256 auctionId;
        Nft[] nfts;
        address seller;
        uint256 startTime;
        uint256 endTime;
        Split split;
    }

    struct Royalty {
        address payable artist;
        uint256 royaltyBasisPoint;
    }

    struct Split {
        address payable recipient;
        uint256 splitBasisPoint;
        address payable charity;
        uint256 charityBasisPoint;
    }

    struct ListingPayment {
        address paymentMethod;
        uint256 price;
    }

    struct PaymentChainlink {
        bool isValid;
        address quoteAddress;
    }

    struct Feature {
        bool feature;
        address paymentMethod;
        uint256 numDays;
        uint256 id;
        address[] tokenAddresses;
        uint256[] tokenIds;
        uint256 price;
    }

    struct AuctionPayment {
        address paymentMethod;
        uint256 initialPrice;
        uint256 buyItNowPrice;
    }

    struct AuctionSignature {
        uint256 auctionId;
        uint256 price;
        address bidder;
        address paymentMethod;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct OfferSignature {
        Nft nft;
        uint256 price;
        address offerer;
        address paymentMethod;
        uint256 expiry;
        address charityAddress;
        uint256 charityBasisPoint;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Nft {
        NftTokenType nftTokenType;
        address nftTokenAddress;
        uint256 nftTokenId;
        uint256 nftNumTokens;
    }
}