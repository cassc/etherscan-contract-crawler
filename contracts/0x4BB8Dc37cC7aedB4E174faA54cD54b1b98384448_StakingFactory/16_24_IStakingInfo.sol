//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title IStakingInfo
    @author iMe Lab
    @notice Staking contract v2 extension, allowing clients to retrieve 
    staking programme information.

    Generally, needed for building better UX by allowing users to see staking
    requisites, lifespan, fees, etc.
 */
interface IStakingInfo {
    /**
        @notice General staking information
     */
    struct StakingInfo {
        /**
            @notice Staking name to be displayed everywhere
         */
        string name;
        /**
            @notice Partner name. As example, iMe Lab
         */
        string author;
        /**
            @notice Partner website. As example, https://imem.app
         */
        string website;
        /**
            @notice Address of token for staking
         */
        address token;
        /**
            @notice Interest per accrual period
            @dev Represented as fixed 2x18 number
         */
        uint64 interestRate;
        /**
            @notice Interest accrual period in seconds
         */
        uint32 accrualPeriod;
        /**
            @notice Duration of withdrawn tokens lock, in seconds
         */
        uint32 delayedWithdrawalDuration;
        /**
            @notice Impact needed to enable compound accrual
         */
        uint256 compoundAccrualThreshold;
        /**
            @notice Fee taken for delayed withdrawn tokens
            @dev Represented as fixed 2x18 number
         */
        uint64 delayedWithdrawalFee;
        /**
            @notice Fee taken for premature withdrawn tokens
            @dev Represented as fixed 2x18 number
         */
        uint64 prematureWithdrawalFee;
        /**
            @notice Minimal LIME rank needed to make deposits
         */
        uint8 minimalRank;
        /**
            @notice Staking start moment
         */
        uint64 startsAt;
        /**
            @notice Staking end moment. May change if staking stops
         */
        uint64 endsAt;
    }

    /**
        @notice Event, typically fired when staking info changes
     */
    event StakingInfoChanged();

    /**
        @notice Retrieve staking information

        @dev Information shouldn't change frequently
     */
    function info() external view returns (StakingInfo memory);
}