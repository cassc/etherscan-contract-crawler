/* SPDX-License-Identifier: MIT */
pragma solidity ^0.8.17;

library SCOA {
    struct AlicePTR {
        address namespace;
        uint8 curve;
        bytes32 index;
    }
    struct Identity {
        address owner;
        AlicePTR alicePTR;
        address authority;
    }
    struct Certificate {
        AlicePTR alicePTR;
        uint256 identity;
    }
}