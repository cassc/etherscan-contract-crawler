/*
GysrUtils

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./MathUtils.sol";

/**
 * @title GYSR utilities
 *
 * @notice this library implements utility methods for the GYSR multiplier
 * and spending mechanics
 */
library GysrUtils {
    using MathUtils for int128;

    // constants
    uint256 public constant GYSR_PROPORTION = 1e16; // 1%

    /**
     * @notice compute GYSR bonus as a function of usage ratio, stake amount,
     * and GYSR spent
     * @param gysr number of GYSR token applied to bonus
     * @param amount number of tokens or shares to unstake
     * @param total number of tokens or shares in overall pool
     * @param ratio usage ratio from 0 to 1
     * @return multiplier value
     */
    function gysrBonus(
        uint256 gysr,
        uint256 amount,
        uint256 total,
        uint256 ratio
    ) internal pure returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        if (total == 0) {
            return 0;
        }
        if (gysr == 0) {
            return 1e18;
        }

        // scale GYSR amount with respect to proportion
        uint256 portion = (GYSR_PROPORTION * total) / 1e18;
        if (amount > portion) {
            gysr = (gysr * portion) / amount;
        }

        // 1 + gysr / (0.01 + ratio)
        uint256 x = 2 ** 64 + (2 ** 64 * gysr) / (1e16 + ratio);

        return
            1e18 +
            (uint256(int256(int128(uint128(x)).logbase10())) * 1e18) /
            2 ** 64;
    }
}