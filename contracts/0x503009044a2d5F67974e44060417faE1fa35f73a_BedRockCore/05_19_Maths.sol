// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

uint256 constant INTERNAL_DENOMINATOR = 1_000_000_000_000_000_000; // 10 ^ 18

/**
 * @dev This is the library of common used mathematical functions
 */
library Maths {
    /*
     */
    function normalizeFraction(uint256 numerator, uint256 denominator) internal pure returns (uint256) {
        return (numerator * INTERNAL_DENOMINATOR) / denominator;
    }
}