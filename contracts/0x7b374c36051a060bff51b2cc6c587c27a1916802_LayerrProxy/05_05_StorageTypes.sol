// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/// @dev Simple struct to store a string value in a custom storage slot
struct StringValue {
    string value;
}

/// @dev Simple struct to store an address value in a custom storage slot
struct AddressValue {
    address value;
}