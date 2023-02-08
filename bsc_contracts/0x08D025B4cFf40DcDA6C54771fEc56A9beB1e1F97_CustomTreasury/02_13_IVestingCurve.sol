// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/// @notice VestingCurve interface to allow for simple updates of vesting release schedules.
interface IVestingCurve {
    /**
     * @notice Returns the vested token amount given the inputs below.
     * @param totalPayout Total payout vested once the vestingTerm is up
     * @param vestingTerm Length of time in seconds that tokens are vesting for
     * @param startTimestamp The timestamp of when vesting starts
     * @param checkTimestamp The timestamp to calculate vested tokens
     * @return vestedPayout Total payoutTokens vested at checkTimestamp
     *
     * Requirements
     * - MUST return 0 if checkTimestamp is less than startTimestamp
     * - MUST return totalPayout if checkTimestamp is greater than startTimestamp + vestingTerm,
     * - MUST return a value including or between 0 and totalPayout
     */
    function getVestedPayoutAtTime(
        uint256 totalPayout,
        uint256 vestingTerm,
        uint256 startTimestamp,
        uint256 checkTimestamp
    ) external view returns (uint256 vestedPayout);
}