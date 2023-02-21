// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct MembersOnlyExtraData {
    address member;
    bytes32 orderHash;
    uint32 deadline;
}