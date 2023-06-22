// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

struct NiftyType {
    bool isMinted; // 1 bytes
    uint72 niftyType; // 9 bytes
    uint88 idFirst; // 11 bytes
    uint88 idLast; // 11 bytes
}