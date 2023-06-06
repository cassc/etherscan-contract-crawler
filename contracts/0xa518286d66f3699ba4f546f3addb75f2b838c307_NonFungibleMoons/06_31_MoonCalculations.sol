// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title MoonCalculations
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
library MoonCalculations {
    // Only need the 4 moon phases where the moon is actually changing,
    // as the other phases (new moon, first quarter, full moon, third quarter)
    // are just single points in time (don't define a rate of change)
    enum MoonPhase {
        WAXING_CRESCENT,
        WAXING_GIBBOUS,
        WANING_GIBBOUS,
        WANING_CRESCENT
    }

    uint256 internal constant BASE_NEW_MOON_DATE_IN_MS = 1666694910000;
    uint256 internal constant LUNAR_MONTH_LENGTH_IN_MS = 2551442877;

    uint256 internal constant NUM_PHASES = 4;
    uint256 internal constant PHASE_LENGTH = 10000 / NUM_PHASES;

    function timestampToPhase(uint256 unixUtcTimestamp)
        internal
        pure
        returns (MoonPhase phase, uint256 progressPercentageOutOf10000)
    {
        uint256 distanceIntoLunarCycleOutOf10000 = calculateLunarCycleDistanceFromDate(
                unixUtcTimestamp
            );

        uint256 progress = distanceIntoLunarCycleOutOf10000 / PHASE_LENGTH;
        phase = MoonPhase(progress);
        progressPercentageOutOf10000 =
            (distanceIntoLunarCycleOutOf10000 - progress * PHASE_LENGTH) *
            NUM_PHASES;
    }

    function calculateLunarCycleDistanceFromDate(uint256 currDate)
        internal
        pure
        returns (uint256 distanceIntoLunarCycleOutOf10000)
    {
        uint256 msIntoPhase = (currDate - BASE_NEW_MOON_DATE_IN_MS) %
            LUNAR_MONTH_LENGTH_IN_MS;

        uint256 value = MoonCalculations.roundToNearestMultiple(
            msIntoPhase * 10000,
            LUNAR_MONTH_LENGTH_IN_MS
        ) / LUNAR_MONTH_LENGTH_IN_MS;

        // Return value between 0 and 9999, inclusive
        return value < 10000 ? value : 0;
    }

    // Helpers

    function roundToNearestMultiple(uint256 number, uint256 multiple)
        internal
        pure
        returns (uint256)
    {
        uint256 result = number + multiple / 2;
        return result - (result % multiple);
    }
}