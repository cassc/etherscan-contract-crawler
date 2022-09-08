// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract WavePortal {
    /* variable for wave count*/
    uint256 total;
    /* variable to rng */
    uint private seed;
    /* create event for wave */
    event newWave(address indexed from, uint256 timestamp, string message);
    /* data struct for wave */
    struct Wave {
        address waver; // address of user sending wave
        string message; // message sent by user
        uint256 timestamp; // timestamp user sent message
    }

    /* storing array of waves */
    Wave[] waves;

    /* creating mapping for address with last time waved*/
    mapping(address => uint256) public lastWaved;

    constructor() payable {
        console.log("This is a test smart contract");
        // set initial rng seed
        seed = (block.timestamp + block.difficulty) % 100;
    }

    /* function for waving */
    function wave(string memory _message) public {
        // make sure timestamp is at least 15 minutes since last wave
        require(
            lastWaved[msg.sender] + 15 minutes < block.timestamp,
            "Wait 15 minutes before waving again!"
        );
        // update current timestamp for user
        lastWaved[msg.sender] = block.timestamp;

        total += 1;
        console.log("%s waved!", msg.sender, _message);
        // storing wave data in array
        waves.push(Wave(msg.sender, _message, block.timestamp));
        // generate new rng seed
        seed = (block.difficulty + block.timestamp + seed) % 100;
        console.log("Random # generated: %d", seed);
        // give user odds to win prize
        if (seed < 50) {
            console.log("%s won!", msg.sender);
            // send prize 
            uint256 prize = 0.00025 ether;
            require(
                prize <= address(this).balance,
                "Trying to withdraw more than stored in contract."
            );
            (bool success, ) = (msg.sender).call{value: prize}("");
            require(success, "Failed to withdraw money from contract.");
        }
        // emit event for message sent
        emit newWave(msg.sender, block.timestamp, _message);
    }

    /* function to return waves array */
    function getAll() public view returns (Wave[] memory) {
        return waves;
    } 

    /* function to get total amount of waves */
    function getTotal() public view returns (uint256) {
        console.log("%d people have waved!", total);
        return total;
    }
}