// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRoomContractMin {
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

    struct Room {
        uint256 uid;
        uint128 startTime;
        uint128 endTime;
        address owner_of;
        uint16 roomOwnerPercentage;
        uint16 artistPercentage;
        uint16 artworkOwnerPercentage;
        address curatorAddress;
        uint16 curatorPercentage;
        uint256 roomerFee;
        uint256 price;
        bool on_sale;
        uint128 tokensApproved;
        bool auction_approved;
    }

    function proposeTokenToRoom(TokenObject memory tokenInfo) external;

    function updateRoomOwner(uint256 _roomId, address _newOwner) external;

    function rooms(uint256 id) external returns (Room memory _room);
}