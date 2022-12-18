// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../storage/IStorage.sol";
import "../tokens/ERC20/IRoomerToken.sol";
import "../tokens/ERC721/IRoomNFT.sol";
import "../tokens/ERC1155/IAccessToken.sol";
import "./interface/IArtroomManager.sol";

contract ArtroomManager is IArtroomManager, ReentrancyGuard {
    IStorage public storageContract;
    IRoomNFT public roomNFT;
    IRoomerToken public roomerToken;
    IAccessToken public accessToken;
    uint256 public roomCreationFee;

    constructor(
        address _storageContract,
        address _roomNFT,
        address _roomerToken,
        address _accessToken,
        uint256 _roomCreationFee
    ) {
        storageContract = IStorage(_storageContract);
        roomNFT = IRoomNFT(_roomNFT);
        roomerToken = IRoomerToken(_roomerToken);
        accessToken = IAccessToken(_accessToken);
        roomCreationFee = _roomCreationFee;
    }

    modifier onlyOwner() {
        require(storageContract.owners(msg.sender), "021");
        _;
    }

    modifier onlyCurator(uint256 room_id) {
        require(
            msg.sender == storageContract.rooms(room_id).curator_address,
            "003"
        );
        _;
    }

    modifier onlyArtroomNFT {
        require(msg.sender == address(roomNFT), "031");
        _;
    }

    function _transferRoomer(address _from, address _to, uint256 _amount) internal {
        require(
            roomerToken.transferFrom(_from, _to, _amount),
            "039"
        );
    }

    function createArtroom(RoomObject memory item) external {
        if (storageContract.haveRoomsCreated(msg.sender)) {
            roomerToken.burnFrom(msg.sender, roomCreationFee);
        } else {
            storageContract.setRoomCreated(msg.sender);
        }
        uint256 new_id = storageContract.roomsLength(); 
        storageContract.newArtroom(
            IStorage.Room(
                new_id,
                item.startTime,
                item.endTime,
                msg.sender,
                item.roomOwnerPercentage,
                item.roomerPercentage,
                item.artworkOwnerPercentage,
                item.curatorAddress,
                item.curatorPercentage,
                item.roomerFee,
                0,
                0,
                false,
                false
            )
        );
        storageContract.newArtworkCountRegistry(new_id, 38);
        roomNFT.mint(msg.sender, new_id, item.uri);
        if (item.entranceFee > 0) storageContract.setPrivateRoom(new_id, item.entranceFee);
        emit roomCreated(
            RoomCreatedObject(
                new_id,
                item.startTime,
                item.endTime,
                item.roomName,
                msg.sender,
                item.curatorAddress,
                item.roomOwnerPercentage,
                item.roomerPercentage,
                item.artworkOwnerPercentage,
                item.curatorPercentage,
                item.roomerFee,
                item.entranceFee,
                item.description,
                item.uri,
                item.location
            )
        );
    }

    function approveRoomAuction(uint256 _room_id) external onlyCurator(_room_id) {
        IStorage.Room memory _room = storageContract.rooms(_room_id);
        require(!_room.auction_approved, "021");
        _room.auction_approved = true;
        storageContract.updateArtroom(_room_id, _room);
        emit auctionApproved(_room_id);
    }

    function buyAccess(uint256 _room_id) external {
        uint256 _entryFee = storageContract.privateRooms(_room_id); 
        require(_entryFee > 0, "037");
        require(roomerToken.balanceOf(msg.sender) >= _entryFee, "038");
        uint256 _halfFee = _entryFee / 2;
        _transferRoomer(msg.sender, storageContract.rooms(_room_id).owner_of, _halfFee);
        _transferRoomer(msg.sender, storageContract.rooms(_room_id).curator_address, _entryFee - _halfFee);
        accessToken.mintAccess(msg.sender, _room_id);
    }

    function updateCurator(uint256 _room_id, address _newCurator) external {
        IStorage.Room memory _room = storageContract.rooms(_room_id);
        require(msg.sender == _room.owner_of, "035");
        _room.curator_address = _newCurator;
        storageContract.updateArtroom(_room_id, _room);
        emit roomCuratorUpdated(_room_id, _newCurator);
    }

    function updateRoomOwner(uint256 _room_id, address _newOwner) external override onlyArtroomNFT {
        IStorage.Room memory _room = storageContract.rooms(_room_id);
        _room.owner_of = _newOwner;
        storageContract.updateArtroom(_room_id, _room);
        emit roomOwnerUpdated(_room_id, _newOwner);
    }

    function putRoomOnSale(uint256 _room_id, uint256 _price) external {
        require(_price != 0, "036");
        IStorage.Room memory _room = storageContract.rooms(_room_id);
        require(msg.sender == _room.owner_of, "032");
        require(!_room.on_sale, "016");
        _room.on_sale = true;
        _room.price = _price;
        storageContract.updateArtroom(_room_id, _room);
        emit roomPutOnSale(_room_id, _price);
    }

    function buyRoom(uint256 _room_id) external payable nonReentrant {
        IStorage.Room memory _room = storageContract.rooms(_room_id);
        address old_owner = _room.owner_of;
        require(msg.sender != old_owner, "033");
        require(msg.value >= _room.price, "034");
        _room.price = 0;
        _room.on_sale = false;
        storageContract.updateArtroom(_room_id, _room);
        payable(old_owner).transfer(msg.value);
        roomNFT.safeTransferFrom(old_owner, msg.sender, _room_id);
        emit roomSold(_room_id, msg.value, old_owner, msg.sender);
    }

    function updateRoomCreationFee(uint256 _newRoomCreationFee) external onlyOwner {
        roomCreationFee = _newRoomCreationFee;
    }

    function setTokens(
        address _roomNFT,
        address _roomerToken,
        address _accessToken
    ) external onlyOwner {
        roomNFT = IRoomNFT(_roomNFT);
        roomerToken = IRoomerToken(_roomerToken);
        accessToken = IAccessToken(_accessToken);
    }
}