// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct LockInfo {
    address owner;
    uint48 unlockAt;
}

struct StakeMultipleInputs {
    uint256 tokenId;
    uint256 lockTime;
}