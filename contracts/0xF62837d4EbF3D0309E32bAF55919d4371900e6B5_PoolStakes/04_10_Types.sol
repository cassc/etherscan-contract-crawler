// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev To save gas, params are packed to fit into a single storage slot.
 * Some amounts are scaled (divided) by {SCALE} - note names starting with
 * the letter "s" (stands for "scaled") followed by a capital letter.
 */
struct PoolParams {
    // if `true`, allocation gets pre-minted, otherwise minted when vested
    bool isPreMinted;
    // if `true`, the owner may change {start} and {duration}
    bool isAdjustable;
    // (UNIX) time when vesting starts
    uint32 start;
    // period in days (since the {start}) of vesting
    uint16 vestingDays;
    // scaled total amount to (ever) vest from the pool
    uint48 sAllocation;
    // out of {sAllocation}, amount (also scaled) to be unlocked on the {start}
    uint48 sUnlocked;
    // amount vested from the pool so far (without scaling)
    uint96 vested;
}