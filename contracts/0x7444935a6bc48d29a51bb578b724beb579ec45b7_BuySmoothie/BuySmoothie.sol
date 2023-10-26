/**
 *Submitted for verification at Etherscan.io on 2023-10-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract BuySmoothie {
    uint256 totalSmoothies;
    address payable public owner;

    constructor() payable {
        owner = payable(msg.sender);
    }

    event NewSmoothie (
        address indexed from,
        uint256 timestamp,
        string message,
        string name
    );

    struct Smoothie {
        address sender;
        string message;
        string name;
        uint256 timestamp;
    }

    Smoothie[] smoothie;

    function getAllSmoothies() public view returns (Smoothie[] memory) {
        return smoothie;
    }    

    function getTotalSmoothies() public view returns (uint256) {
        return totalSmoothies;
    }

    function buySmoothie(
        string memory _message,
        string memory _name
    ) payable public {
        require(msg.value == 0.01 ether, "You need to pay 0.01 ETH");

        totalSmoothies += 1;
        smoothie.push(Smoothie(msg.sender, _message, _name, block.timestamp));

        (bool success,) = owner.call{value: msg.value}("");
        require(success, "Failed to send Ether to owner");

        emit NewSmoothie(msg.sender, block.timestamp, _message, _name);
    }
}