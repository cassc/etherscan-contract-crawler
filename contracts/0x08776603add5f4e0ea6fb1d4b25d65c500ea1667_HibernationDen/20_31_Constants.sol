// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Constants {
    // User permissions
    bytes32 internal constant GAME_ADMIN = "GAME_ADMIN";
    bytes32 internal constant BEEKEEPER = "BEEKEEPER";
    bytes32 internal constant JANI = "JANI";

    // Contract instances
    bytes32 internal constant GAME_INSTANCE = "GAME_INSTANCE";
    bytes32 internal constant GATEKEEPER = "GATEKEEPER";
    bytes32 internal constant PORTAL = "PORTAL";

    // Special ERC permissions
    bytes32 internal constant MINTER = "MINTER";
    bytes32 internal constant BURNER = "BURNER";
}