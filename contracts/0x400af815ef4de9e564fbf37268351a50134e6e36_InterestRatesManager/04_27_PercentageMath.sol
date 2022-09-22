// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

/// @title PercentageMath.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Optimized version of Aave V3 math library PercentageMath to conduct percentage manipulations: https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/math/PercentageMath.sol
library PercentageMath {
    ///	CONSTANTS ///

    uint256 internal constant PERCENTAGE_FACTOR = 1e4;
    uint256 internal constant HALF_PERCENTAGE_FACTOR = 0.5e4;
    uint256 internal constant MAX_UINT256 = 2**256 - 1;
    uint256 internal constant MAX_UINT256_MINUS_HALF_PERCENTAGE = 2**256 - 1 - 0.5e4;

    /// ERRORS ///

    // Thrown when percentage is above 100%.
    error PercentageTooHigh();

    /// INTERNAL ///

    /// @notice Executes a percentage multiplication.
    /// @param x The value of which the percentage needs to be calculated.
    /// @param percentage The percentage of the value to be calculated.
    /// @return y The result of the multiplication.
    function percentMul(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // Let percentage > 0
        // Overflow if x * percentage + HALF_PERCENTAGE_FACTOR > type(uint256).max
        // <=> x * percentage > type(uint256).max - HALF_PERCENTAGE_FACTOR
        // <=> x > (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        assembly {
            if mul(percentage, gt(x, div(MAX_UINT256_MINUS_HALF_PERCENTAGE, percentage))) {
                revert(0, 0)
            }

            y := div(add(mul(x, percentage), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }

    /// @notice Executes a percentage division.
    /// @param x The value of which the percentage needs to be calculated.
    /// @param percentage The percentage of the value to be calculated.
    /// @return y The result of the division.
    function percentDiv(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // let percentage > 0
        // Overflow if x * PERCENTAGE_FACTOR + halfPercentage > type(uint256).max
        // <=> x * PERCENTAGE_FACTOR > type(uint256).max - halfPercentage
        // <=> x > type(uint256).max - halfPercentage / PERCENTAGE_FACTOR
        assembly {
            y := div(percentage, 2)
            if iszero(mul(percentage, iszero(gt(x, div(sub(MAX_UINT256, y), PERCENTAGE_FACTOR))))) {
                revert(0, 0)
            }

            y := div(add(mul(x, PERCENTAGE_FACTOR), y), percentage)
        }
    }

    /// @notice Executes a weighted average, given an interval [x, y] and a percent p: x * (1 - p) + y * p
    /// @param x The value at the start of the interval (included).
    /// @param y The value at the end of the interval (included).
    /// @param percentage The percentage of the interval to be calculated.
    /// @return the average of x and y, weighted by percentage.
    function weightedAvg(
        uint256 x,
        uint256 y,
        uint256 percentage
    ) internal pure returns (uint256) {
        if (percentage > PERCENTAGE_FACTOR) revert PercentageTooHigh();

        return percentMul(x, PERCENTAGE_FACTOR - percentage) + percentMul(y, percentage);
    }
}