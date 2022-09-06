// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title IOpenSkyInterestRateStrategy
 * @author OpenSky Labs
 * @notice Interface for the calculation of the interest rates
 */
interface IOpenSkyInterestRateStrategy {
    /**
     * @dev Emitted on setBaseBorrowRate()
     * @param reserveId The id of the reserve
     * @param baseRate The base rate has been set
     **/
    event SetBaseBorrowRate(
        uint256 indexed reserveId,
        uint256 indexed baseRate
    );

    /**
     * @notice Returns the borrow rate of a reserve
     * @param reserveId The id of the reserve
     * @param totalDeposits The total deposits amount of the reserve
     * @param totalBorrows The total borrows amount of the reserve
     * @return The borrow rate, expressed in ray
     **/
    function getBorrowRate(uint256 reserveId, uint256 totalDeposits, uint256 totalBorrows) external view returns (uint256); 
}