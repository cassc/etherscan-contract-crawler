// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

struct VestingSchedule {
    // cliff period in seconds
    uint64 cliff;
    // start time of the vesting period
    uint64 start;
    // duration of the vesting period in seconds
    uint64 duration;
    // duration of a slice period for the vesting in seconds
    uint64 slicePeriodSeconds;
    // total amount of tokens to be released at the end of the vesting
    uint256 amountTotal;
    // amount of tokens released
    uint256 released;
    // beneficiary of tokens after they are released
    address beneficiary;
    bool initialized;
    // whether or not the vesting has been revoked
    bool revoked;
    // whether or not the vesting is revocable
    bool revocable;
}