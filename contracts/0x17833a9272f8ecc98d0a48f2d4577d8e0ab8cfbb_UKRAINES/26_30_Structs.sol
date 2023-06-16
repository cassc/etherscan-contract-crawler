// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface Structs {
    struct Curio {    // 256 bits available
        uint8 slotId;        // 8
        uint80 mintPrice;    // 88
        uint16 maxSupply;    // 104
        uint16 totalSupply;  // 120
        uint8 slotCollision; // 128
        bool soulbound;      // 136
        bool mintable;       // 144
        bool publicMint;     // 152
        bool signedMint;     // 160
        uint16 minGeneration; // 176
        uint16 maxGeneration; // 192
        uint16 thread;        // 208
        bool locked;          // 216
        uint40 timestamp;     // 256
    }
}