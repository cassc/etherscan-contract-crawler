// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVerifiedSlot {
    struct VerifiedSlot {
        address minter;
        uint16 mintingCapacity;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}