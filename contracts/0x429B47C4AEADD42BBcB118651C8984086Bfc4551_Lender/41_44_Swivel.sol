// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

library Swivel {
    // the components of a ECDSA signature
    struct Components {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Order {
        bytes32 key;
        uint8 protocol;
        address maker;
        address underlying;
        bool vault;
        bool exit;
        uint256 principal;
        uint256 premium;
        uint256 maturity;
        uint256 expiry;
    }
}