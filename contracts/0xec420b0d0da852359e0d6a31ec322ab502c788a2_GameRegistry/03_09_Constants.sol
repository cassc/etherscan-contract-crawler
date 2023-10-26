// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Constants {
    /**
     * Could use ENUM however existing contracts are already using these so opting to keep things consistent.
     */
    bytes32 internal constant GAME_ADMIN = "GAME_ADMIN";
    bytes32 internal constant BEEKEEPER = "BEEKEEPER";
    bytes32 internal constant JANI = "JANI";

    // Contract instances
    bytes32 internal constant GAME_INSTANCE = "GAME_INSTANCE";
    bytes32 internal constant GATEKEEPER = "GATEKEEPER";

    // Special ERC permissions
    bytes32 internal constant MINTER = "MINTER";
    bytes32 internal constant BURNER = "BURNER";
}