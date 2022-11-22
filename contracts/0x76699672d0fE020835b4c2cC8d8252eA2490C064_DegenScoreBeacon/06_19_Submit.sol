// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @dev the payload sent by the user to submit traits
struct UserPayload {
    /// @dev the timestamp the payload was created at
    uint64 createdAt;
    /// @dev the account the data belongs to
    address account;
    /// @dev the Beacon ID
    uint128 beaconId;
    /// @dev the price the user needs to pay to submit the data
    uint128 price;
    /// @dev the traits of the user
    TraitData[] traits;
}

/// @dev describes a primary Trait in the `UserPayload`
struct TraitData {
    /// @dev the ID of the Trait
    uint256 id;
    /// @dev the value of the Trait
    uint192 value;
}