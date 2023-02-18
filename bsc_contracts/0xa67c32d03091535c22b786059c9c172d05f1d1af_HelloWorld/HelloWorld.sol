/**
 *Submitted for verification at BscScan.com on 2023-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract HelloWorld {
    string public message = "Hello";

    string public constant MESSAGE_CONSTANT = "Hello";

    address public constant DONATION_ADDRESS =
        0x8ee38F06f161A072eE04387bCF5d710032733E09;

    address public immutable OWNER;

    constructor () {
        OWNER = msg.sender;
    }

    function greetings() public pure returns (string memory) {
        string memory internalmessage = "Hello";

        return internalmessage;
    }

    function getBlockNumber() public view returns (uint256) {
        return block.timestamp;
    }
}