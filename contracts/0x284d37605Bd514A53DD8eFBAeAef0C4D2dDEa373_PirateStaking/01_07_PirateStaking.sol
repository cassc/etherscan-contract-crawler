// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPirateMetadata {
     function getTribeForPirate(uint256) external view returns (uint8);
}

contract PirateStaking is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;

    uint256 public stakedPirateCount;
    IERC721 public piratesContract;
    IPirateMetadata public metadataContract;
    mapping(uint8 => EnumerableSet.AddressSet) addressesByTribe;
    mapping(address => EnumerableSet.UintSet) piratesByPlayer;
    mapping(uint256 => address) pirateOwners;

    mapping(uint8 => mapping (address => uint256)) tribeCountByPlayer; // tribe => owner => staked count
    mapping(uint8 => uint256) countPerTribe;

    constructor() { }

    function getAddressesByTribe(uint8 tribe) external view returns (address[] memory) {
        address[] memory result = new address[](addressesByTribe[tribe].length());
        for (uint8 i; i < addressesByTribe[tribe].length(); i++){
            result[i] = addressesByTribe[tribe].at(i);
        }
        return result;
    }

    function getCountPerTribe(uint8 tribe) external view returns (uint256) {
        return countPerTribe[tribe];
    }

    function getTribeCountForPlayer(address player, uint8 tribe) external view returns (uint256){
        return tribeCountByPlayer[tribe][player];
    }

    function setPiratesContract(address piratesContract_) external onlyOwner {
        piratesContract = IERC721(piratesContract_);
    }

    function setMetadataContract(address metadataContract_) external onlyOwner {
        metadataContract = IPirateMetadata(metadataContract_);
    }

    function addPirates(uint256[] calldata pirateIds) external {
        for (uint i = 0; i < pirateIds.length; i++) {
            addPirate(pirateIds[i]);
        }
    }

    function addPirate(uint256 pirateId) public {
        require(piratesContract.ownerOf(pirateId) == msg.sender, "Sender is not owner");
        piratesContract.transferFrom(msg.sender, address(this), pirateId);
        pirateOwners[pirateId] = msg.sender;
        if (!piratesByPlayer[msg.sender].contains(pirateId)){
            piratesByPlayer[msg.sender].add(pirateId);
        }   
        stakedPirateCount++;
        uint8 tribe = metadataContract.getTribeForPirate(pirateId);
        tribeCountByPlayer[tribe][msg.sender]++;
        countPerTribe[tribe]++;
        addressesByTribe[tribe].add(msg.sender);
    }

    function removePirate(uint256 pirateId) public {
        require(pirateOwners[pirateId] == msg.sender, "Sender is not owner");
        require(piratesByPlayer[msg.sender].contains(pirateId), "Sender doesn't own pirate");
        piratesContract.transferFrom(address(this), msg.sender, pirateId);
        piratesByPlayer[msg.sender].remove(pirateId);
        pirateOwners[pirateId] = address(0);
        stakedPirateCount--;
        uint8 tribe = metadataContract.getTribeForPirate(pirateId);
        tribeCountByPlayer[tribe][msg.sender]--;
        countPerTribe[tribe]--;
        if (tribeCountByPlayer[tribe][msg.sender] == 0) {
            addressesByTribe[tribe].remove(msg.sender);
        }
    }

    function removePiratesForPlayer(uint256[] calldata pirateIds) external { 
        for (uint i = 0; i < pirateIds.length; i++) {
           removePirate(pirateIds[i]);
       }
    }

    function getStakedPiratesForPlayer(address player) external view returns (uint256[] memory){
        uint length = piratesByPlayer[player].length();
        uint256[] memory result = new uint256[](length);
        for (uint256 i; i < length; i++) {
            result[i] = piratesByPlayer[player].at(i);
        }
        return result;
    }
}