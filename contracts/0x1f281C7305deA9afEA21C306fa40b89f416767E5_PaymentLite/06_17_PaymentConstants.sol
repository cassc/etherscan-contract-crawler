// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

abstract contract PaymentConstants {
    /* Access roles */

    /// @dev owner role of the contract and admin over all existing access-roles
    bytes32 internal constant OWNER_ROLE = keccak256("OWNER_ROLE");

    /// @dev access-role used for pausing/unpausing the contract
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @dev access-role used for adding/removing nodes to/from distribution protocol
    bytes32 internal constant NODE_MANAGER_ROLE = keccak256("NODE_MANAGER_ROLE");

    /// @dev access-role used for updating per-node addons
    bytes32 internal constant UPDATE_ADDON_ROLE = keccak256("UPDATE_ADDON_ROLE");

    /// @dev access-role used for finalizing epochs
    bytes32 internal constant FINALIZE_EPOCH_ROLE = keccak256("FINALIZE_EPOCH_ROLE");

    /// @dev access-role used for finalizing nodes
    bytes32 internal constant FINALIZE_NODE_ROLE = keccak256("FINALIZE_NODE_ROLE");

    /* Constants */

    /// @dev placeholder for rewards accumulator to optimize node finalizations
    uint8 internal constant REWARD_PLACEHOLDER = 1;

    /// @dev normalizer for percentages of double digit precision
    uint16 internal constant MAX_PPM = 10_000;

    /// @dev maximum allowed addon value for a node (1000%)
    uint32 internal constant MAX_ADDON = 10 * uint32(MAX_PPM);

    /// @dev maximum allowed deposit token denomination
    uint8 internal constant TOKEN_PRECISION = 18;
}