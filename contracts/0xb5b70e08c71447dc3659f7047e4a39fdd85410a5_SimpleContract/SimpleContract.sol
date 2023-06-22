/**
 *Submitted for verification at Etherscan.io on 2023-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleContract {
    uint256 public value;

    function updateValue(uint256 newValue) public {
        value = newValue;
    }
}