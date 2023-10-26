// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

struct MerkleDistribution {
    string manifest;
    bytes32 merkleRoot;
    uint256 amount;
    address returnTokenAddress;
}