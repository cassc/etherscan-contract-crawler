// SPDX-License-Identifier: MIT

/// @title The Whole Town Is Waiting
/// @author transientlabs.xyz

pragma solidity 0.8.19;

import {Doppelganger} from "tl-creator-contracts/doppelganger/Doppelganger.sol";

contract TheWholeTownIsWaiting is Doppelganger {

    constructor(
        string memory name,
        string memory symbol,
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address initOwner,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    ) Doppelganger(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        name,
        symbol,
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        initOwner,
        admins,
        enableStory,
        blockListRegistry
    ) {}
}