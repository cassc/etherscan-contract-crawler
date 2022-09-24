// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

struct Quest {
    bool isActive;
    uint32 questId;
    uint64 startTimestamp;
    uint32 arrayIndex;
}