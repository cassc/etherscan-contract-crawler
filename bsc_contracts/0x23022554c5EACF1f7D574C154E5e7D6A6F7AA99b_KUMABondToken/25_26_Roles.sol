// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Roles {
    bytes32 public constant MCAG_MINT_ROLE = keccak256("MCAG_MINT_ROLE");
    bytes32 public constant MCAG_BURN_ROLE = keccak256("MCAG_BURN_ROLE");
    bytes32 public constant MCAG_BLACKLIST_ROLE = keccak256("MCAG_BLACKLIST_ROLE");
    bytes32 public constant MCAG_PAUSE_ROLE = keccak256("MCAG_PAUSE_ROLE");
    bytes32 public constant MCAG_UNPAUSE_ROLE = keccak256("MCAG_UNPAUSE_ROLE");
    bytes32 public constant MCAG_TRANSMITTER_ROLE = keccak256("MCAG_TRANSMITTER_ROLE");
    bytes32 public constant MCAG_MANAGER_ROLE = keccak256("MCAG_MANAGER_ROLE");
    bytes32 public constant MCAG_SET_URI_ROLE = keccak256("MCAG_SET_URI_ROLE");
}