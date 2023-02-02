// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IVestingCurve {
    /**
     * @notice Returns the vested token amount given the inputs below.
     * @param totalPayout Total payout vested once the vestingTerm is up
     * @param vestingTerm Length of time in seconds that tokens are vesting for
     * @param startTimestamp The timestamp of when vesting starts
     * @param checkTimestamp The timestamp to calculate vested tokens
     *
     * Requirements
     * - If checkTimestamp is less than startTimestamp, return 0
     * - If checkTimestamp is greater than startTimestamp + vestingTerm, return totalPayout
     */
    function getVestedPayoutAtTime(
        uint256 totalPayout,
        uint256 vestingTerm,
        uint256 startTimestamp,
        uint256 checkTimestamp
    ) external pure returns (uint256 vestedPayout_);
}