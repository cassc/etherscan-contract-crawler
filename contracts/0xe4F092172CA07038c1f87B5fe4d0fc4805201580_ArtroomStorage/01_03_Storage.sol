// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../helpers/DelegateOwnership.sol";
import "./IStorageMin.sol";

contract ArtroomStorage is DelegateOwnership, IStorageMin {
    address public NFTManager;
    address public artroomManager;

    mapping(address => bool) public haveRoomsCreated;
    mapping(uint256 => uint256) public privateRooms;
    mapping(uint256 => uint256) public tokensOnSale;
    mapping(uint256 => uint256) public feesAvailable;
    mapping(uint256 => address[]) public artists;
    mapping(uint256 => uint16[]) public artworksOwnerAmt;
    mapping(uint256 => uint256) public tokenSubmitTime;

    Room[] public rooms;
    Token[] public tokens;
    Offer[] public offers;

    modifier onlyNFTManager {
        require(msg.sender == NFTManager, "700");
        _;
    }

    modifier onlyArtroomManager {
        require(msg.sender == artroomManager, "701");
        _;
    }

    modifier onlyManager {
        require(msg.sender == NFTManager || msg.sender == artroomManager, "702");
        _;
    }

    function getArtists(uint256 _uid) external view returns (address[] memory) {
        return artists[_uid];
    }

    function getArtworksOwnerAmount(uint256 _uid) external view returns (uint16[] memory) {
        return artworksOwnerAmt[_uid];
    }

    function upgradeArtroomManager(address _newArtroomManager) external onlyOwner {
        artroomManager = _newArtroomManager;
    }
    
    function upgradeNFTManager(address _newNFTManager) external onlyOwner {
        NFTManager = _newNFTManager;
    }

    function updateArtroom(uint256 _uid, Room memory _updatedRoom) external onlyManager {
        rooms[_uid] = _updatedRoom;
    }

    function updateToken(uint256 _uid, Token memory _updatedToken) external onlyNFTManager {
        tokens[_uid] = _updatedToken;
    }

    function updateOffer(uint256 _uid, Offer memory _updatedOffer) external onlyNFTManager {
        offers[_uid] = _updatedOffer;
    }

    function newArtroom(Room memory _newRoom) external onlyArtroomManager {
        rooms.push(_newRoom);
    }

    function newToken(Token memory _newToken) external onlyNFTManager {
        tokens.push(_newToken);
    }
 
    function newOffer(Offer memory _newOffer) external onlyNFTManager {
        offers.push(_newOffer);
    }

    function newArtworkCountRegistry(uint256 _uid, uint256 _size) external onlyArtroomManager {
        artists[_uid] = new address[](_size);
        artworksOwnerAmt[_uid] = new uint16[](_size);
    }

    function setRoomCreated(address _creator) external onlyArtroomManager {
        haveRoomsCreated[_creator] = true;
    }

    function setPrivateRoom(uint256 _uid, uint256 _entranceFee) external onlyArtroomManager {
        privateRooms[_uid] = _entranceFee;
    }

    function setTokensOnSale(uint256 _uid, uint256 _amount) external onlyNFTManager {
        tokensOnSale[_uid] = _amount;
    }
    
    function setFeesAvailable(uint256 _uid, uint256 _amount) external onlyNFTManager {
        feesAvailable[_uid] = _amount;
    }

    function setArtistsById(uint256 _uid, uint16 _index, address _artist) external onlyNFTManager {
        artists[_uid][_index] = _artist;
    }

    function setArtworksOwnerAmountById(uint256 _uid, uint16 _index, uint16 _amount) external onlyNFTManager {
        artworksOwnerAmt[_uid][_index] = _amount;
    }

    function setTokenSubmitTime(uint256 _uid, uint256 _timestamp) external onlyNFTManager {
        tokenSubmitTime[_uid] = _timestamp;
    }

    function roomsLength() external view returns (uint256) {
        return rooms.length;
    }

    function tokensLength() external view returns (uint256) {
        return tokens.length;
    }

    function offersLength() external view returns (uint256) {
        return offers.length;
    }
}