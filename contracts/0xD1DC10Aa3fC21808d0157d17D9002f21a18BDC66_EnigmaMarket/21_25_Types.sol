// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/* An ECDSA signature. */
struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}