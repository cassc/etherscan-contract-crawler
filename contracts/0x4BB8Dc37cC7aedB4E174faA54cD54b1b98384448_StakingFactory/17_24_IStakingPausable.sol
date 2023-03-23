//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title IStakingPausable
    @author iMe Lab

    @notice Staking v2 extension, allowing managers to stop programmes.
 */
interface IStakingPausable {
    /**
        @notice Error, typically fired on attempt to do something during pause
     */
    error StakingIsPaused();

    /**
        @notice Temporary forbid user deposits/withdrawals
        Makes no sense after staking finish.
     */
    function pause() external;

    /**
        @notice Resume paused staking
     */
    function resume() external;
}