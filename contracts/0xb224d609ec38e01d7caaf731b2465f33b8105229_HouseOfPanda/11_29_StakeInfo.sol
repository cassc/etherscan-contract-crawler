pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

/**
 *
 * This code is a part of the House of Panda project.
 *
 */

struct StakeInfo {
    uint32 qty;
    uint32 term; // term in months
    uint64 startTime;
    uint256 accumRewards;
    uint256 claimedRewards;
}