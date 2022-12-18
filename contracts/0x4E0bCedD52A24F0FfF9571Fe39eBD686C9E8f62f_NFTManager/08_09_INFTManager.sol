// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTManager {
    struct Room {
        uint256 uid;
        uint128 startTime;
        uint128 endTime;
        address owner_of;
        uint16 room_owner_percentage;
        uint16 artist_percentage;
        uint16 artwork_owner_percentage;
        address[38] artists;
        uint8[38] artworks_owner_amt;
        address curatorAddress;
        uint16 curatorPercentage;
        uint256 roomerFee;
        uint256 price;
        uint128 tokensApproved;
        bool on_sale;
        bool auction_approved;
    }
    
    struct TokenObject {
        address token_address;
        uint256 token_id;
        uint256 room_id;
        uint256 price;
        uint256 amount;
        uint128 start_time;
        uint128 end_time;
        bool is_auction;
        bool is_physical;
        address owner;
    }

    struct FeeRecipient {
        address recipient;
        uint16 percentage;
    }

    event tokenProposed(TokenObject tokenInfo, uint256 uid);
    event proposalCancelled(uint256 uid);

    event tokenApproved(bool isAuction, uint256 uid);
    event tokenRejected(bool isAuction, uint256 uid);
    event saleCancelled(uint256 uid, address curator);
    event tokenSold(
        uint256 uid,
        address old_owner,
        address new_owner,
        uint256 amount,
        uint256 total_price
    );
    event roomerRoyaltiesPayed(uint256 room_id, uint256 total_value);
    
    event bidAdded(uint256 auctId, uint256 highest_bid, address highest_bidder);
    event auctionFinalized(uint256 auctId, bool approve);
    
    event offerMade(address token_address, uint256 token_id, uint256 offer_id, uint256 price, uint256 amount, address bidder);
    event offerCancelled(uint256 offer_id);
    event offerResolved(uint256 offer_id, bool approved, address from);
}