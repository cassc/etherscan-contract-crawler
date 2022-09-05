//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

pragma experimental ABIEncoderV2;

/**
 * @notice A library for calculating and storing accumulations of time-weighted average values in the form of sumations
 *   of (value * time).
 */
library AccumulationLibrary {
    /**
     * @notice A struct for storing a snapshot of liquidity accumulations.
     * @dev The difference of a newer snapshot against an older snapshot can be used to derive time-weighted average
     *   liquidities by dividing the difference in value by the difference in time.
     */
    struct LiquidityAccumulator {
        /*
         * @notice Accumulates time-weighted average liquidity of the token in the form of a sumation of (price * time),
         *   with time measured in seconds.
         * @dev Overflow is desired and results in correct behavior as long as the difference between two snapshots
         *   is less than or equal to 2^112.
         */
        uint112 cumulativeTokenLiquidity;
        /*
         * @notice Accumulates time-weighted average liquidity of the quote token in the form of a sumation of
         *   (price * time), with time measured in seconds..
         * @dev Overflow is desired and results in correct behavior as long as the difference between two snapshots
         *   is less than or equal to 2^112.
         */
        uint112 cumulativeQuoteTokenLiquidity;
        /*
         * @notice The unix timestamp (in seconds) of the last update of (addition to) the cumulative price.
         */
        uint32 timestamp;
    }

    /**
     * @notice A struct for storing a snapshot of price accumulations.
     * @dev The difference of a newer snapshot against an older snapshot can be used to derive a time-weighted average
     *   price by dividing the difference in value by the difference in time.
     */
    struct PriceAccumulator {
        /*
         * @notice Accumulates time-weighted average prices in the form of a sumation of (price * time), with time
         *   measured in seconds.
         * @dev Overflow is desired and results in correct behavior as long as the difference between two snapshots
         *   is less than or equal to 2^112.
         */
        uint112 cumulativePrice;
        /*
         * @notice The unix timestamp (in seconds) of the last update of (addition to) the cumulative price.
         */
        uint32 timestamp;
    }
}