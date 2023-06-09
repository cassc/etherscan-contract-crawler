// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

struct SignatureStatus {
    bool isSalted;
    bool isVerified;
    address signer;
    bytes32 saltedHash;
}