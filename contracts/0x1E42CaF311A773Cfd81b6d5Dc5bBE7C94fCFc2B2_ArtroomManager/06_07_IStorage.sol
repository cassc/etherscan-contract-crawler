// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStorage {
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

    function owners(address _user) external view returns (bool);
    function getArtists(uint256 _uid) external view returns (address[] memory);
    function getArtworksOwnerAmount(uint256 _uid) external view returns (uint16[] memory);

    function rooms(uint256 _uid) external view returns (Room memory);
    function tokens(uint256 _uid) external view returns (Token memory);
    function offers(uint256 _uid) external view returns (Offer memory);
    function artists(uint256 _uid) external view returns (address[] memory);
    function artworksOwnerAmt(uint256 _uid) external view returns (uint16[] memory);

    function privateRooms(uint256 _uid) external view returns (uint256);
    function haveRoomsCreated(address _creator) external view returns (bool);
    function tokensOnSale(uint256 _uid) external view returns (uint256);
    function feesAvailable(uint256 _uid) external view returns (uint256);
    function tokenSubmitTime(uint256 _uid) external view returns (uint256);
    
    function updateArtroom(uint256 _uid, Room memory _updatedRoom) external;
    function updateToken(uint256 _uid, Token memory _updatedToken) external;
    function updateOffer(uint256 _uid, Offer memory _updatedOffer) external;
    
    function newArtroom(Room memory _newRoom) external;
    function newToken(Token memory _newToken) external;
    function newOffer(Offer memory _newOffer) external;
    function newArtworkCountRegistry(uint256 _uid, uint256 _size) external;

    function setRoomCreated(address _creator) external;
    function setPrivateRoom(uint256 _uid, uint256 _entranceFee) external;
    function setTokensOnSale(uint256 _uid, uint256 _amount) external;
    function setFeesAvailable(uint256 _uid, uint256 _amount) external;
    function setArtistsById(uint256 _uid, uint16 _index, address _artist) external;
    function setArtworksOwnerAmountById(uint256 _uid, uint16 _index, uint16 _amount) external;
    function setTokenSubmitTime(uint256 _uid, uint256 _timestamp) external;

    function roomsLength() external view returns (uint256);
    function tokensLength() external view returns (uint256);
    function offersLength() external view returns (uint256);
}