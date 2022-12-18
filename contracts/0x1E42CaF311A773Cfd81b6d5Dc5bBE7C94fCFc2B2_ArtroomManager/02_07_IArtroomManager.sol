// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArtroomManager {
    struct RoomObject {
        uint128 startTime;
        uint128 endTime;
        string roomName;
        address curatorAddress;
        uint16 roomOwnerPercentage;
        uint16 roomerPercentage;
        uint16 artworkOwnerPercentage;
        uint16 curatorPercentage;
        uint256 roomerFee;
        uint256 entranceFee;
        string description;
        string uri;
        string location;
    }

    struct RoomCreatedObject {
        uint256 uid;
        uint128 startTime;
        uint128 endTime;
        string roomName;
        address owner_of;
        address curatorAddress;
        uint16 roomOwnerPercentage;
        uint16 roomerPercentage;
        uint16 artworkOwnerPercentage;
        uint16 curatorPercentage;
        uint256 roomerFee;
        uint256 entranceFee;
        string description;
        string uri;
        string location;
    }

    function updateRoomOwner(uint256 _room_id, address _newOwner) external;

    event roomCreated(RoomCreatedObject room);
    event roomOwnerUpdated(uint256 room_id, address new_owner);
    event roomCuratorUpdated(uint256 room_id, address new_curator);
    
    event auctionApproved(uint256 room_id);

    event roomPutOnSale(uint256 room_id, uint256 price);
    event roomSold(
        uint256 room_id,
        uint256 price,
        address old_owner,
        address new_owner
    );
}