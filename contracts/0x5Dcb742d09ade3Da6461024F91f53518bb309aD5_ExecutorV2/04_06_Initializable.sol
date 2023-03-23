// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Initializable {
    bool internal isInited;

    modifier whenInitialized() {
        require(isInited, "not initialized");
        _;
    }

    modifier whenNotInitialized() {
        require(!isInited, "already initialized");
        _;
    }
}