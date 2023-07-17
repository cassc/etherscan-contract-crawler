/**
 *Submitted for verification at Etherscan.io on 2023-06-24
*/

/**
 *Submitted for verification at Arbiscan on 2023-06-12
*/

// SPDX-License-Identifier: MIT



pragma solidity ^0.8.17;

contract Bulk {
    address private immutable owner;

    constructor() {
        owner = msg.sender;
    }
    function batch_eths(string[] calldata hexData) external payable {
        for (uint i = 0; i < hexData.length; i++) {
            (bool success, ) = msg.sender.call{value: 0}(bytes(hexData[i]));
            require(success, "External call failed");
        }
    }
}