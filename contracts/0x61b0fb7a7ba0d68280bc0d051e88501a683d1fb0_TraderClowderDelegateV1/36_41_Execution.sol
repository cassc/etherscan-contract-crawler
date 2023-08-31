// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

struct Execution {
    address collection; // zero to evaluate as non-existant
    uint256 buyPrice;
    uint256 tokenId;
}