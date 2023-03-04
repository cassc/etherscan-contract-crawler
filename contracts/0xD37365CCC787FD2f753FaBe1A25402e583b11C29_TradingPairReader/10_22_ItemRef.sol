// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/// @dev reference to the item
struct ItemRef {
    address addr; // referenced contract address
    uint256 id; // id of the item
}