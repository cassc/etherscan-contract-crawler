//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

/// @title ConfigTypes library
/// @author leNFT
/// @notice Defines the types used as configuration parameters of the protocol
/// @dev Library with the types used as configuration parameters throughout the protocol
library ConfigTypes {
    /// @param maxLiquidatorDiscount The maximum discount liquidators can get when liquidating a certain collateral with a certain price (10000 = 100%)
    /// @param auctioneerFee The fee borrowers have to pay to the auctioneer when repaying a loan after liquidation (% of debt, 10000 = 100%)
    /// @param liquidationFee The fee liquidators have to pay to the protocol when liquidating a loan (10000 = 100%)
    /// @param maxUtilizationRate The maximum utilization rate of the pool for withdrawals
    struct LendingPoolConfig {
        uint64 maxLiquidatorDiscount;
        uint64 auctioneerFeeRate;
        uint64 liquidationFeeRate;
        uint64 maxUtilizationRate;
    }

    /// @param optimalUtilization The optimal utilization rate for the market (10000 = 100%)
    /// @param baseBorrowRate The market's base borrow rate (10000 = 100%)
    /// @param lowSlope The slope of the interest rate model when utilization rate is below the optimal utilization rate (10000 = 100%)
    /// @param highSlope The slope of the interest rate model when utilization rate is above the optimal utilization rate (10000 = 100%)
    struct InterestRateConfig {
        uint64 optimalUtilizationRate;
        uint64 optimalBorrowRate;
        uint64 baseBorrowRate;
        uint64 lowSlope;
        uint64 highSlope;
    }
}