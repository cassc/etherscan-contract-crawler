// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.18;

/**
 * @dev Number of distinct color traits.
 */
uint8 constant NUM_COLORS = 8;

/**
 * @dev Number of distinct body types.
 */
uint8 constant NUM_BODIES = 8;

library TraitSampling {
    /**
     * @notice Masks the rightmost 128 bits
     */
    uint256 private constant _MASK_128 = ((1 << 128) - 1);

    /**
     * @notice Unity for probablilities in a fix-point arithmetic sense.
     */
    uint256 private constant _PROBABILITY_ONE = 10_000;

    /**
     * @notice Samples a color trait from a given random seed;
     */
    function sampleColor(uint128 seed) internal pure returns (uint8) {
        return uint8(seed % NUM_COLORS);
    }

    /**
     * @notice Samples a body trait from a given random seed;
     */
    function sampleBody(uint128 seed) internal pure returns (uint8) {
        uint256 rand = seed % _PROBABILITY_ONE;

        // Birdkeeper 12.5%
        // Birdwatcher 12.5%
        // Crescent 18.75%
        // Guardian 18.75%
        // Monster 6.25%
        // Phoenix 6.25%
        // Skelly 6.25%
        // Tabby 18.75%
        uint256[NUM_BODIES] memory cdf =
            [1250, 2500, 4375, 6250, 6875, 7500, 8125, _PROBABILITY_ONE];

        // Opting to not do a binary search here even though it will only need
        // 3/8 of the checks in the worst case because the individual checks
        // will get more complicated and expensive so that we won't be
        // necessarily save gas in the end. Also this will only be used in a
        // view function.
        for (uint256 i; true; ++i) {
            if (rand < cdf[i]) {
                return uint8(i);
            }
        }

        return 0;
    }

    /**
     * @notice Samples the color and body traits from a given random seed.
     */
    function sampleColorAndBody(uint256 seed)
        internal
        pure
        returns (uint8 color, uint8 body)
    {
        color = sampleColor(uint128(seed >> 128));
        body = sampleBody(uint128(seed & _MASK_128));
    }
}