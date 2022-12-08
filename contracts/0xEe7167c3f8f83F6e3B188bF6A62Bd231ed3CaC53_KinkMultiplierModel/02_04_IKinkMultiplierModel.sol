// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

interface IKinkMultiplierModel {
    /**
     * @notice Gets the approximate number of blocks per year that is assumed by the interest rate model
     */
    function blocksPerYear() external view returns (uint256);

    /**
     * @notice Gets the multiplier of utilisation rate that gives the slope of the interest rate
     */
    function interestRateMultiplierPerBlock() external view returns (uint256);

    /**
     * @notice Gets the initial interest rate which is the y-intercept when utilisation rate is 0
     */
    function initialRatePerBlock() external view returns (uint256);

    /**
     * @notice Gets the interestRateMultiplierPerBlock after hitting a specified utilisation point
     */
    function kinkCurveMultiplierPerBlock() external view returns (uint256);

    /**
     * @notice Gets the utilisation point at which the kink curve multiplier is applied
     */
    function kinkPoint() external view returns (uint256);

    /**
     * @notice Calculates the utilisation rate of the market: `borrows / (cash + borrows - protocol interest)`
     * @param cash The amount of cash in the market
     * @param borrows The amount of borrows in the market
     * @param protocolInterest The amount of protocol interest in the market
     * @return The utilisation rate as a mantissa between [0, 1e18]
     */
    function utilisationRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest
    ) external pure returns (uint256);
}