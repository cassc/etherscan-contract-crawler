// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Randomiser {

    function tokenHash(string memory seed, uint256 uid, string memory attName ) public pure returns (uint256){
        return uint256(keccak256(abi.encodePacked(seed, uid, attName)));
    }

    function randomX(string memory seed, uint256 instId, string memory attName, uint maxNum) public pure returns (uint8) {
        uint256 hash = tokenHash(seed, instId, attName);
        return uint8( hash % maxNum);
    }

    function selectByRarity(uint8 rawValue, uint8[] memory rarities) public pure returns(uint8) {
        uint8 i;
        for(i = 0; i < rarities.length; i++) {
            if(rawValue < rarities[i]) {
                break;
            }
        }
        return i;
    }

}