// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract OnlySender {

    modifier onlySender {
        require(msg.sender == tx.origin, "No smart contracts!");
        _;
    }
    
}