// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./libraries/LibAsset.sol";

contract ExchangeDomain {

    struct SellRequest{
        LibAsset.Asset asset;

        address currency;
        uint256 price;

        bool isTimedAuction;
        uint256 expirationTime;
    }

    struct CreateAndSellRequest{
        LibAsset.Asset asset;
        string uri;

        address currency;
        uint256 price;
        
        uint96 royalty;

        bool isTimedAuction;
        uint256 expirationTime;
    }

    struct SellInfo{
        uint256 tokenAmount;

        address currency;
        uint256 price;

        address lastBidder;
        uint256 lastBid;

        bool isTimedAuction;
        uint256 expirationTime;

        bool sold;
    }

    struct BuyRequest{
        address seller;
        LibAsset.Asset asset;
    }

    mapping (address => mapping (address => mapping (uint256 => SellInfo))) public sellinfos;


    struct BidRequest{
        address seller;
        LibAsset.Asset asset;

        uint256 price;
    }

    struct RewardBidRequest{
        address seller;
        LibAsset.Asset asset;
    }

    struct CanRewardBidRequest {
        address seller;
        address token;
        uint256 tokenId;
    }
}