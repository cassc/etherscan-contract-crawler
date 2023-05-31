// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.0;

contract TristansAge {
    uint256 public storedInteger = 21;
    address private owner;
    uint256 private birthTimestamp = 1015440000; // March 6, 2002, in Unix timestamp

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    function updateAge() public {
        uint256 currentAge = (block.timestamp - birthTimestamp) / 31557600; // 31557600 seconds in a year (average)
        if (storedInteger < currentAge) {
            storedInteger = currentAge;
        }
    }
}