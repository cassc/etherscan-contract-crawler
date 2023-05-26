// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../storage/LibOwnableStorage.sol";


abstract contract ReentrancyGuard {

    constructor() {
        LibOwnableStorage.Storage storage stor = LibOwnableStorage.getStorage();
        if (stor.reentrancyStatus == 0) {
            stor.reentrancyStatus = 1;
        }
    }

    modifier nonReentrant() {
        LibOwnableStorage.Storage storage stor = LibOwnableStorage.getStorage();
        require(stor.reentrancyStatus == 1, "ReentrancyGuard: reentrant call");
        stor.reentrancyStatus = 2;
        _;
        stor.reentrancyStatus = 1;
    }
}