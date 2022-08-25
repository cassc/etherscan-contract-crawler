// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {WadRayMath} from './WadRayMath.sol';

library MathUtils {
    using WadRayMath for uint256;

    /// @dev Ignoring leap years
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /**
     * @dev Function to calculate the interest accumulated using a linear interest rate formula
     * @param rate The interest rate, in ray
     * @param lastUpdateTimestamp The timestamp of the last update of the interest
     * @return The interest rate linearly accumulated during the timeDelta, in ray
     **/

    function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp) external view returns (uint256) {
        //solium-disable-next-line
        uint256 timeDifference = block.timestamp - (uint256(lastUpdateTimestamp));

        return (rate * timeDifference) / SECONDS_PER_YEAR + WadRayMath.ray();
    }

    function calculateBorrowInterest(
        uint256 borrowRate,
        uint256 amount,
        uint256 duration
    ) external pure returns (uint256) {
        return amount.rayMul(borrowRate.rayMul(duration).rayDiv(SECONDS_PER_YEAR));
    }

    function calculateBorrowInterestPerSecond(uint256 borrowRate, uint256 amount) external pure returns (uint256) {
        return amount.rayMul(borrowRate).rayDiv(SECONDS_PER_YEAR);
    }

    function calculateLoanSupplyRate(
        uint256 availableLiquidity,
        uint256 totalBorrows,
        uint256 borrowRate
    ) external pure returns (uint256 loanSupplyRate, uint256 utilizationRate) {
        utilizationRate = (totalBorrows == 0 && availableLiquidity == 0)
            ? 0
            : totalBorrows.rayDiv(availableLiquidity + totalBorrows);
        loanSupplyRate = utilizationRate.rayMul(borrowRate);
    }
}