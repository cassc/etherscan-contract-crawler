// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@thirdweb-dev/contracts/extension/Permissions.sol";

import {INiftyKitCollection} from "../interfaces/INiftyKitCollection.sol";

contract BurnerContract is Permissions {
    error BurnerContract__NotOwner();

    INiftyKitCollection private targetCollection;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setCollection(
        address _targetCollection
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        targetCollection = INiftyKitCollection(_targetCollection);
    }

    function burn(uint256 tokenId) public {
        address owner = targetCollection.ownerOf(tokenId);
        if (owner != msg.sender) {
            revert BurnerContract__NotOwner();
        }
        targetCollection.burn(tokenId);
    }

    function batchBurn(uint256[] calldata tokenIds) public {
        uint256 length = tokenIds.length;

        for (uint256 i = 0; i < length; i++) {
            address owner = targetCollection.ownerOf(tokenIds[i]);
            if (owner != msg.sender) {
                revert BurnerContract__NotOwner();
            }
        }
        for (uint256 i = 0; i < length; i++) {
            targetCollection.burn(tokenIds[i]);
        }
    }
}