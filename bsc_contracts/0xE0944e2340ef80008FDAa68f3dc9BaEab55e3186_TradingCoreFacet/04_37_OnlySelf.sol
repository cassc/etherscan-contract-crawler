// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract OnlySelf {

    // Functions that add the onlySelf modifier can eliminate many basic parameter checks, such as address != address(0), etc.
    modifier onlySelf() {
        require(msg.sender == address(this), "only self call");
        _;
    }
}