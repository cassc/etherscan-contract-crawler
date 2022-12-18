// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStorageMin {
    struct Room {
        uint256 uid;
        uint128 start_time;
        uint128 end_time;
        address owner_of;
        uint16 room_owner_percentage;
        uint16 artist_percentage;
        uint16 artwork_owner_percentage;
        address curator_address;
        uint16 curator_percentage;
        uint256 roomer_fee;
        uint256 price;
        uint128 tokens_approved;
        bool on_sale;
        bool auction_approved;
    }

    struct Token {
        uint256 uid;
        address token_address;
        address owner_of;
        uint256 token_id;
        uint256 room_id;
        uint256 price;
        uint256 amount;
        uint256 highest_bid;
        address highest_bidder;
        uint128 start_time;
        uint128 end_time;
        bool approved;
        bool resolved;
        bool is_auction;
    }
    
    struct Offer {
        address token_address;
        uint256 token_id;
        uint256 price;
        uint256 amount;
        address bidder;
        bool approved;
        bool resolved;
    }
}