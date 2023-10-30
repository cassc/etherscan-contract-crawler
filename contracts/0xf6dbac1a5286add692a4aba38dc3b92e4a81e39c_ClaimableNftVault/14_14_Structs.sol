// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct Claim {
    address admin;
    uint256 supply;
    bytes32 merkleRoot;
    mapping(address => bool) claimers;
}