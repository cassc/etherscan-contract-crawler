// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @dev Only TRANSFER_ROLE holders can have tokens transferred from or to them, during restricted transfers.
bytes32 constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
/// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s.
bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");