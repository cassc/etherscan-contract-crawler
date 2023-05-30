// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Random {    
    uint private randNonce;
    
    constructor(uint randomSeed) {
        randNonce = randomSeed;
    }

    function randMod(uint _modulus) internal returns(uint) {
        randNonce++;         
        return uint(keccak256(abi.encodePacked(
            block.timestamp,             
            block.difficulty, 
            msg.sender, 
            randNonce))) % _modulus;
     }
}