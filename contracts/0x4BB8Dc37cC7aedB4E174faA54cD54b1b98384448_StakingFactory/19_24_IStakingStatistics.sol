//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title IStakingStatistics
    @author iMe Lab
    @notice Staking contract v2 extension, allowing clients to
    see their own statistics

    Generally, needed to improve UX by showing users their staked, accrued
    and delayed token amounts.
 */
interface IStakingStatistics {
    /**
        @notice Staking stats, related to a certain investor
     */
    struct StakingStatistics {
        uint256 impact;
        uint256 debt;
        uint256 pendingWithdrawnTokens;
        uint256 readyWithdrawnTokens;
    }

    /**
        @notice Yields personal stats for a certain investor
     */
    function statsOf(address) external view returns (StakingStatistics memory);
}