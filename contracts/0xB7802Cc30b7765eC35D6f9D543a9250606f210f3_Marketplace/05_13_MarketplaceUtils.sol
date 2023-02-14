// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
 
 
contract MarketplaceUtils {

   struct OwnerCollaborators { 
        address payable owner;
        uint64 value; 
    }
    struct MarketItem {
        address creator;  
        uint64  royalities;  
    }
    struct MarketId {
        address  contractCreator;  
        uint256  tokenId;   
    }
    struct MarketSale {
        uint256 id; 
        bool primary; 
        address owner;
        address  highestBidder;
        uint256 time;
        uint256 gap;
        uint256 auctionEndTime;
        uint256 highestBid;
        uint256 price;
        bool inited;
        bool sale;
        bool auction;
        bool ended;
    }
    struct MarketSaleIdToken {
        MarketId marketId; 
        MarketSale marketSale;  
    }
    struct Bid { 
        address payable bidder;
        uint64 value;
    }
     
}