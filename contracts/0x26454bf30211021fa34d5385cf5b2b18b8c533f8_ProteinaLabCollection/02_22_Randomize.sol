// SPDX-License-Identifier: MIT
//Cryptoloteria Contracts (last updated v1.0)
pragma solidity ^0.8.5;

contract Randomize {
    uint256 internal seed;

    constructor() {
        seed = block.timestamp;
    }

    function randomBetween(uint256 a, uint256 b) public  returns (uint){
        return random(a - b) + b;
    }

    function random(uint mod) public returns(uint){
        seed++;
        return uint(keccak256(abi.encodePacked(seed, block.difficulty, msg.sender)))%mod;

    }
}