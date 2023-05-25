// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @notice Different role definitions used by the ACL contract.
library Roles {
    /// @dev This maps directly to the OpenZeppelins AccessControl DEFAULT_ADMIN
    bytes32 public constant ADMIN = 0x00;

    /// @dev The Maintainer role. Can execute Maintainer-only tasks.
    bytes32 public constant MAINTAINER = keccak256("MAINTAINER_ROLE");

    /// @dev The NFT owner role. Can execute NFT-only tasks.
    bytes32 public constant NFT_OWNER = keccak256("NFT_OWNER");

    /// @dev The auxiliary contracts that can perform cross-calls with one another.
    // TODO: segregate these into a smaller roles.
    bytes32 public constant AUXILIARY_CONTRACTS = keccak256("AUXILIARY_CONTRACTS");

    /// @dev The Fragment mini-game burn permission
    bytes32 public constant FRAGMENT_MINI_GAME_BURN = keccak256("FRAGMENT_MINI_GAME_BURN");

    /// @dev The Zee NFT mint permission
    bytes32 public constant ZEE_NFT_MINT = keccak256("ZEE_NFT_MINT");

    /// @dev The Zee NFT burn permission
    bytes32 public constant ZEE_NFT_BURN = keccak256("ZEE_NFT_BURN");
}