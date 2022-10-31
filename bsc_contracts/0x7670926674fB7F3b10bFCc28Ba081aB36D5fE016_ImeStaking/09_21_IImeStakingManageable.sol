//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @title IImeStakingManageable
    @author iMe Group
    @notice Interface for management iMe Staking functionality
 */
interface IImeStakingManageable {
    /**
        @notice Change deposit-ability
     */
    function manageDeposits(bool allowed) external;

    /**
        @notice Change withdrawal-ability
     */
    function manageWithdrawals(bool allowed) external;

    /**
        @notice Set staking lifespan
        
        @dev Reverts with StakingLifespanInvalid if its invalid.
        Also, reverts with StakingLifespanInvalid on attempt to set endsAt to past.
     */
    function setLifespan(uint256 start, uint256 end) external;

    error StakingLifespanInvalid();

    /**
        @notice Set withdrawal fee amount
    
        @param safe Manage safe withdrawal fee or not
        @param fee Fee taken from 10e9
     */
    function setWithdrawalFee(bool safe, uint256 fee) external;

    /**
        @notice Withdraw free tokens from contract balance
        
        @param amount Amount to rescue
        @param to Withdrawn tokens destination

        @dev Reverts with RescueOverFreeTokens if requested too much
     */
    function rescueFunds(uint256 amount, address to) external;

    error RescueOverFreeTokens(uint256 requested, uint256 available);

    /**
        @notice Withdraw all free tokens from contract balance
    
        @param to Withdrawn tokens destination
     */
    function rescueFunds(address to) external;

    /**
        @notice Perform withdrawal for certain investor

        @dev Should throw ForceWithdrawalTooEarly on
        force withdrawal before staking finish
     */
    function forceWithdrawal(address to) external;

    error ForceWithdrawalTooEarly(uint256 notBefore);
}