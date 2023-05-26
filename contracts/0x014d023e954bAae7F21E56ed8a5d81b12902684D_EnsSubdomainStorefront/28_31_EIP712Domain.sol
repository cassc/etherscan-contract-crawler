// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}