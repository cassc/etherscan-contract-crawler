// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Commands {
    /// TODO: Review these masks
    // Masks to extract certain bits of commands
    bytes1 internal constant FLAG_ALLOW_REVERT = 0x80;
    bytes1 internal constant FLAG_CHAIN_ORDER = 0x40;
    bytes1 internal constant FLAG_MULTI_SWAP = 0x20;
    bytes1 internal constant COMMAND_TYPE_MASK = 0x1f;

    // Command Types where value <0x04, first block
    uint256 constant V2_FORK = 0x00; // Was 0x02
    uint256 constant UNISWAP_V2 = 0x01; // Was 0x00
    uint256 constant UNISWAP_V3 = 0x02; // Was 0x05

    // Command Types where value <0x06, second block
    uint256 constant CURVE = 0x03; // Was 0x07
    uint256 constant BALANCER = 0x04; // Was 0x08
    uint256 constant BANCOR = 0x05; // Was 0x09

    // Command Types where value >0x05 and <0x0b, third block
    uint256 constant HOP_BRIDGE = 0x06; // Was 0x0e
    uint256 constant ACROSS_BRIDGE = 0x07; // Was 0x0d
    uint256 constant CELER_BRIDGE = 0x08; // Was 0x0c
    uint256 constant SYNAPSE_BRIDGE = 0x09; // Was 0x0a // Was 0x0f

    // Command Types where value >0x0a <0x0f, fourth block
    uint256 constant STARGATE_BRIDGE = 0x0a; // Was 0x0b // Was 0x19
    uint256 constant ALL_BRIDGE = 0x0b; // Was 0x0a // Was 0x09 // Was 0x0b // Was 0x11 before 0x0b
    uint256 constant MULTICHAIN_BRIDGE = 0x0c; // Was 0x10 // Was 0x0f before 0x10
    uint256 constant HYPHEN_BRIDGE = 0x0d; // Was 0x11 // Was 0x0b before
    uint256 constant PORTAL_BRIDGE = 0x0e; // Was 0x12

    // Command Types where value >0x0e fourth block
    uint256 constant OPTIMISM_BRIDGE = 0x0f; // Was 0x13
    uint256 constant POLYGON_POS_BRIDGE = 0x10; // Was 0x16
    uint256 constant OMNI_BRIDGE = 0x11; // Was 0x18
}