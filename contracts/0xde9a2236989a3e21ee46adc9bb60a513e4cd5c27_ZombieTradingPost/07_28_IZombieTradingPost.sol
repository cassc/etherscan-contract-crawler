// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IZombieTradingPost {
    struct ItemDefinition {
        address executor;
        uint256 cost;
        uint256 purchased;
        uint256 purchaseLimit;
        bool feoEnabled;
        bool enabled;
    }
}