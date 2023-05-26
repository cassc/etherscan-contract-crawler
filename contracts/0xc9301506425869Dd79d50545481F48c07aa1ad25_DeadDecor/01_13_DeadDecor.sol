//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract DeadDecor is ERC721Enumerable,Ownable {

    mapping (address => uint) roomReservations;

    address _proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    uint public constant MAX_SUPPLY = 500;
    uint public _reservedRoomPrice = 0.05 ether;
    uint public _roomPrice = 0.07 ether;
    string public _metadataURI;

    bool public _canBuyReservedRoom = false;
    bool public _canBuyRoom = false;

    constructor(string memory uri) ERC721("Dead Decor Co.", "DDC") {
        _metadataURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _metadataURI;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }

    function maxSupply() external pure returns (uint) {
        return MAX_SUPPLY;
    }

    function reserveRooms(address[] calldata addresses,uint[] calldata roomIds) external onlyOwner {
        for(uint i = 0;i<roomIds.length;i++)
        {
            roomReservations[addresses[i]] = roomIds[i];
        }
    }

    function getReservation(address addr) external view returns (uint) {
        return roomReservations[addr];
    }

    function canBuyReservedRoom() external view returns (bool){
        return _canBuyReservedRoom;
    }

    function toggleCanBuyReservedRoom() external onlyOwner {
        _canBuyReservedRoom = !_canBuyReservedRoom;
    }

    function toggleCanBuyRoom() external onlyOwner {
        _canBuyRoom = !_canBuyRoom;
    }

    function canBuyRoom() external view returns (bool){
        return _canBuyRoom;
    }

    function isApprovedForAll(address owner, address operator)
    override
    public
    view
    returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function setReservedRoomPrice(uint price) external onlyOwner {
        _reservedRoomPrice = price;
    }

    function getReservedRoomPrice() external view returns (uint){
        return _reservedRoomPrice;
    }

    function setRoomPrice(uint price) external onlyOwner {
        _roomPrice = price;
    }

    function getRoomPrice() external view returns (uint){
        return _roomPrice;
    }

    function roomSold(uint roomId) external view returns (bool){
        return _exists(roomId);
    }

    function buyReservedRoom(uint roomId) public payable {
        require(msg.value >= _reservedRoomPrice,"More eth required");
        require(_canBuyReservedRoom,"You cannot buy your room yet.");
        require(roomReservations[msg.sender] == roomId,"This room is not reserved for you.");
        require(!_exists(roomId),"Room already sold.");
        _safeMint(msg.sender, roomId);
    }

    function buyRoom(uint roomId) public payable {
        require(msg.value >= _roomPrice,"More eth required");
        require(roomId > 0 && roomId < (MAX_SUPPLY + 1),"Room does not exist.");
        require(balanceOf(msg.sender) < 3,"You may only mint 3 rooms.");
        require(_canBuyRoom,"You cannot buy your room yet.");
        require(!_exists(roomId),"Room already sold.");
        _safeMint(msg.sender, roomId);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
}