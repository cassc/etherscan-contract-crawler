// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/**
 * @title Tick
 * @author MetaStreet Labs
 */
library Tick {
    /*
     * A tick encodes three conditions on liquidity: limit, duration, and rate.
     * Limit is the maximum depth that liquidity sourced from the node can be
     * used in. Duration is the maximum allowed duration for that liquidity.
     * Rate is the interest rate associated with that liquidity. Duration and
     * rates are encoded as indexes into predetermined, discrete tiers.
     *
     * +-----------------------------------------------------------------------+
     * |                                 128                                   |
     * +--------------------------------------|----------|----------|----------+
     * |                  120                 |    3     |     3    |     2    |
     * |                 Limit                | Dur. Idx | Rate Idx | Reserved |
     * +-----------------------------------------------------------------------+
     *
     * Duration Index is ordered from shortest duration to longest, e.g. 7
     * days, 14 days, 30 days.
     *
     * Rate Index is ordered from lowest rate to highest rate, e.g. 10%, 30%,
     * 50%.
     */

    /**************************************************************************/
    /* Constants */
    /**************************************************************************/

    /**
     * @notice Tick limit mask
     */
    uint256 internal constant TICK_LIMIT_MASK = 0xffffffffffffffffffffffffffffff;

    /**
     * @notice Tick limit shift
     */
    uint256 internal constant TICK_LIMIT_SHIFT = 8;

    /**
     * @notice Tick duration index mask
     */
    uint256 internal constant TICK_DURATION_MASK = 0x7;

    /**
     * @notice Tick duration index shift
     */
    uint256 internal constant TICK_DURATION_SHIFT = 5;

    /**
     * @notice Tick rate index mask
     */
    uint256 internal constant TICK_RATE_MASK = 0x7;

    /**
     * @notice Tick rate index shift
     */
    uint256 internal constant TICK_RATE_SHIFT = 2;

    /**
     * @notice Tick reserved mask
     */
    uint256 internal constant TICK_RESERVED_MASK = 0x3;

    /**
     * @notice Tick reserved shift
     */
    uint256 internal constant TICK_RESERVED_SHIFT = 0;

    /**
     * @notice Maximum number of durations supported
     */
    uint256 internal constant MAX_NUM_DURATIONS = TICK_DURATION_MASK + 1;

    /**
     * @notice Maximum number of rates supported
     */
    uint256 internal constant MAX_NUM_RATES = TICK_RATE_MASK + 1;

    /**************************************************************************/
    /* Errors */
    /**************************************************************************/

    /**
     * @notice Invalid tick
     */
    error InvalidTick();

    /**************************************************************************/
    /* Helper Functions */
    /**************************************************************************/

    /**
     * @dev Decode a Tick
     * @param tick Tick
     * @return limit Limit field
     * @return duration Duration field
     * @return rate Rate field
     * @return reserved Reserved field
     */
    function decode(
        uint128 tick
    ) internal pure returns (uint256 limit, uint256 duration, uint256 rate, uint256 reserved) {
        limit = ((tick >> TICK_LIMIT_SHIFT) & TICK_LIMIT_MASK);
        duration = ((tick >> TICK_DURATION_SHIFT) & TICK_DURATION_MASK);
        rate = ((tick >> TICK_RATE_SHIFT) & TICK_RATE_MASK);
        reserved = ((tick >> TICK_RESERVED_SHIFT) & TICK_RESERVED_MASK);
    }

    /**
     * @dev Validate a Tick (fast)
     * @param tick Tick
     * @param prevTick Previous tick
     * @param minDurationIndex Minimum Duration Index (inclusive)
     * @return Limit field
     */
    function validate(uint128 tick, uint256 prevTick, uint256 minDurationIndex) internal pure returns (uint256) {
        (uint256 limit, uint256 duration, , ) = decode(tick);
        if (tick <= prevTick) revert InvalidTick();
        if (duration < minDurationIndex) revert InvalidTick();
        return limit;
    }

    /**
     * @dev Validate a Tick (slow)
     * @param tick Tick
     * @param minLimit Minimum Limit (exclusive)
     * @param minDurationIndex Minimum Duration Index (inclusive)
     * @param maxDurationIndex Maximum Duration Index (inclusive)
     * @param minRateIndex Minimum Rate Index (inclusive)
     * @param maxRateIndex Maximum Rate Index (inclusive)
     */
    function validate(
        uint128 tick,
        uint256 minLimit,
        uint256 minDurationIndex,
        uint256 maxDurationIndex,
        uint256 minRateIndex,
        uint256 maxRateIndex
    ) internal pure {
        (uint256 limit, uint256 duration, uint256 rate, uint256 reserved) = decode(tick);
        if (limit <= minLimit) revert InvalidTick();
        if (duration < minDurationIndex || duration > maxDurationIndex) revert InvalidTick();
        if (rate < minRateIndex || rate > maxRateIndex) revert InvalidTick();
        if (reserved != 0) revert InvalidTick();
    }
}