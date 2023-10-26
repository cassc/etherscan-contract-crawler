/**
 *Submitted for verification at Etherscan.io on 2023-10-21
*/

// SPDX-Liscence-Identifier: MIT
pragma solidity ^0.8.18;
contract Image {

    address public owner;
    string public hash;
    string public data;

    // You will declare your global vars here
    constructor(string memory newhash, string memory metadata) {
        // You will instantiate your contract here
        owner = msg.sender;
        hash = newhash;
        data = metadata;
    }
}