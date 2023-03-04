// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library Constants {
    // External permissions
    bytes32 public constant GAME_ADMIN = "GAME_ADMIN";
    bytes32 public constant BEEKEEPER = "BEEKEEPER";
    bytes32 public constant JANI = "JANI";

    // Contract instances
    bytes32 public constant GAME_INSTANCE = "GAME_INSTANCE";
    bytes32 public constant BEAR_POUCH = "BEAR_POUCH";
    bytes32 public constant GATEKEEPER = "GATEKEEPER";
    bytes32 public constant GATE = "GATE";

    // Special honeycomb permissions
    bytes32 public constant MINTER = "MINTER";
    bytes32 public constant BURNER = "BURNER";
}