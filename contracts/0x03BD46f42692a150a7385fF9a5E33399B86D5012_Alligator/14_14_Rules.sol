// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct Rules {
    uint8 permissions;
    uint8 maxRedelegations;
    uint32 notValidBefore;
    uint32 notValidAfter;
    uint16 blocksBeforeVoteCloses;
    address customRule;
}