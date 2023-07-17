// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @dev holds a primary Trait
struct Trait {
    /// @dev the timestamp when the Trait was updated
    uint64 updatedAt;
    /// @dev the Trait value
    uint192 value;
}

/// @dev holds data of a Beacon
struct BeaconData {
    /// @dev the ID of the Beacon
    uint128 beaconId;
    /// @dev the timestamp when the Beacon was updated
    uint64 updatedAt;
    /// @dev the primary Trait IDs of the Beacon holder
    uint256[] traitIds;
}