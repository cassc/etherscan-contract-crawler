// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Common {
    struct Distribution {
        bytes32 identifier;
        address token;
        bytes32 merkleRoot;
        bytes32 proof;
    }
}