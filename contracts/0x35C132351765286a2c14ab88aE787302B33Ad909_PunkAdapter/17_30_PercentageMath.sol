// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/**
 * @title PercentageMath library
 * @author Bend
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
    uint256 public constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
    uint256 public constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;
    uint256 public constant ONE_PERCENT = 1e2; //100, 1%
    uint256 public constant TEN_PERCENT = 1e3; //1000, 10%
    uint256 public constant ONE_THOUSANDTH_PERCENT = 1e1; //10, 0.1%
    uint256 public constant ONE_TEN_THOUSANDTH_PERCENT = 1; //1, 0.01%

    /**
     * @dev Executes a percentage multiplication
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The percentage of value
     **/
    function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256) {
        if (value == 0 || percentage == 0) {
            return 0;
        }

        require(value <= (type(uint256).max - HALF_PERCENT) / percentage, "MATH_MULTIPLICATION_OVERFLOW");

        return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
    }
}