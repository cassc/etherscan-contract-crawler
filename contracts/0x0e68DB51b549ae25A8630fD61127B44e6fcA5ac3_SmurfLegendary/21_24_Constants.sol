// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract SmurfConstants {
    // Roles
    bytes32 constant public URI_SETTER_ROLE         = keccak256("URI_SETTER_ROLE");
    bytes32 constant public PAUSER_ROLE             = keccak256("PAUSER_ROLE");
    bytes32 constant public MINTER_ROLE             = keccak256("MINTER_ROLE");
    bytes32 constant public RARIBLE_ROLE            = keccak256("RARIBLE_ROLE");

    // Used for checking signature
    bytes32 constant public CRYSTAL_TYPE_HASH       = keccak256("MintCrystal(address owner,uint token)");
    bytes32 constant public CRYSTALS_TYPE_HASH      = keccak256("MintCrystals(address owner,uint[] tokens)");

    // Crystals
    uint[25] public PERCENTAGES_BPS;
    uint[5] public PHASE_QUANTITY;

    // General Smurfs
    uint public constant CRYSTAL_RANGES = 25;
    uint public constant PHASE_RANGES = 100_000;
    uint public constant REVEALED_RANGE = 1_000_000;
    uint public constant MAX_SUPPLY_PER_SMURF = 50;

    uint public constant PHASE_CRYSTALS = 0;
    uint public constant PHASE_HACKER_SMURF = 1;
    uint public constant PHASE_BUCKET = 2;
    uint public constant PHASE_BLUELIST = 3;
    uint public constant PHASE_FRENS = 4;
    uint public constant MAX_PHASE_ID = 5;
}