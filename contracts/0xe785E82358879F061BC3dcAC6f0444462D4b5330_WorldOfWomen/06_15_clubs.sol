// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Clubs is Ownable {

    using SafeMath for uint256;

    Club[3] internal arrayClubs;

    modifier clubExist(uint256 id) {
        require(id < arrayClubs.length, "This club does not exist.");
        _;
    }

    struct Club {
        string name;
        uint256[] tokens;
        bool locked;
    }

    constructor() {
        arrayClubs[0] = Club("Curators", new uint256[](0), false);
        arrayClubs[1] = Club("Royalties", new uint256[](0), false);
        arrayClubs[2] = Club("Traders", new uint256[](0), false);
    }

    function getClub(uint256 id) external view clubExist(id) returns(Club memory) {
        return arrayClubs[id];
    }

    function addClubToken(uint256 id, uint256 _tokenId) external onlyOwner clubExist(id) {
        require(!arrayClubs[id].locked, "Club is locked.");

        bool isAlreadyInClub = false;
        for (uint256 i; i < arrayClubs[id].tokens.length; i++) {
            if (arrayClubs[id].tokens[i] == _tokenId) {
                isAlreadyInClub = true;
            }
        }

        if (!isAlreadyInClub) {
            arrayClubs[id].tokens.push(_tokenId);
        }
    }

    function updateClubToken(uint256 id, uint256 _oldTokenId, uint256 _newTokenId) external onlyOwner clubExist(id) {
        require(!arrayClubs[id].locked, "Club is locked.");

        for (uint256 i; i < arrayClubs[id].tokens.length; i++) {
            if (arrayClubs[id].tokens[i] == _oldTokenId) {
                arrayClubs[id].tokens[i] = _newTokenId;
            }
        }
    }

    function lockClub(uint256 id) external onlyOwner clubExist(id) {
        require(!arrayClubs[id].locked, "Club is locked.");

        arrayClubs[id].locked = true;
    }
}