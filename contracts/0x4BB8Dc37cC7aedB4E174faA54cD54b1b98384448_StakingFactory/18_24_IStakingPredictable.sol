//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title IStakingPredictable
    @author iMe Lab
    @notice Staking contract v2 extension, allowing clients to retrieve
    staking current statistics and predict debt in future.

    Generally, needed to predict staking solvency.
 */
interface IStakingPredictable {
    /**
        @notice Totals in this staking
     */
    struct StakingSummary {
        uint256 totalImpact;
        uint256 totalDebt;
        uint256 totalDelayed;
        uint256 balance;
    }

    /**
        @notice Populate staking summary for the present moment
     */
    function summary() external view returns (StakingSummary memory);

    /**
        @notice Predict total debt for a certain point in time

        @param at Unit in time to make a prediction. Shouldn't be in the past.
     */
    function totalDebt(uint64 at) external view returns (uint256);
}