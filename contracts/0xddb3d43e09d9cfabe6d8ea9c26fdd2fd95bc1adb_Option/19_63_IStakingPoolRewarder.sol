// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/**
 * @title IStakingPoolRewarder interface
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @dev Interface for calculating and distributing staking pool rewards
 */
interface IStakingPoolRewarder {
    /**
     * @notice Calculate the total amount of reward tokens for the specified user and pool ID
     * @dev Calculates the total amount of reward tokens for the specified user and pool ID
     * @param user The address of the user to calculate rewards for
     * @param poolId The ID of the staking pool to calculate rewards for
     * @return The total amount of reward tokens for the specified user and pool ID
     */
    function calculateTotalReward(address user, uint256 poolId) external view returns (uint256);

    /**
     * @notice Calculate the amount of reward tokens that can be withdrawn by the specified user and pool ID
     * @dev Calculates the amount of reward tokens that can be withdrawn by the specified user and pool ID
     * @param user The address of the user to calculate rewards for
     * @param poolId The ID of the staking pool to calculate rewards for
     * @return The amount of reward tokens that can be withdrawn by the specified user and pool ID
     */
    function calculateWithdrawableReward(address user, uint256 poolId) external view returns (uint256);

    /**
     * @notice Update the vesting schedule and claimable amounts for the specified user and pool ID
     * @dev Calculates and updates the user's vested and unvested token amounts based on their staking activity, and adds any vested tokens to the user's claimable amounts.
     * @param poolId The ID of the staking pool to update vesting schedule and claimable amounts for
     * @param user The address of the user to update vesting schedule and claimable amounts for
     * @param amount The amount of reward tokens earned by the user
     * @param entryTime The timestamp of the user's entry into the staking pool
     */
    function onReward(uint256 poolId, address user, uint256 amount, uint256 entryTime) external;

    /**
     * @notice Claim vested reward tokens for the specified user and pool ID
     * @dev Claims vested reward tokens for the specified user and pool ID
     * @param poolId The ID of the staking pool to claim rewards from
     * @param user The address of the user to claim rewards for
     * @return The amount of vested reward tokens claimed by the specified user and pool ID
     */
    function claimVestedReward(uint256 poolId, address user) external returns (uint256);
}