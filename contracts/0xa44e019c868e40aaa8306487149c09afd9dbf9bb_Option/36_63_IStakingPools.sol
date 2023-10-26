// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/**
 * @title IStakingPools interface
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @dev Interface for staking pools contract
 */
interface IStakingPools {
    /**
     * @notice Create a new staking pool
     * @dev Creates a new staking pool with the specified parameters
     * @param token The address of the ERC20 token contract to be staked
     * @param optionContract The address of the Option contract
     * @param startBlock The block number at which staking begins
     * @param endBlock The block number at which staking ends
     * @param rewardPerBlock The amount of reward tokens to be distributed per block
     */
    function createPool(
        address token,
        address optionContract,
        uint256 startBlock,
        uint256 endBlock,
        uint256 rewardPerBlock
    ) external;

    /**
     * @notice Extend the end block of a staking pool
     * @dev Extends the end block of a staking pool with the specified pool ID
     * @param poolId The ID of the staking pool to extend
     * @param newEndBlock The new end block of the staking pool
     */
    function extendEndBlock(uint256 poolId, uint256 newEndBlock) external;

    /**
     * @notice Get the staking amount for a user and pool ID
     * @dev Gets the staking amount for the specified user and pool ID
     * @param user The address of the user to get the staking amount for
     * @param poolId The ID of the staking pool to get the staking amount for
     * @return The staking amount for the specified user and pool ID
     */
    function getStakingAmountByPoolID(address user, uint256 poolId) external returns (uint256);

    /**
     * @notice Stake tokens on behalf of a user
     * @dev Stakes tokens on behalf of the specified user for the specified staking pool
     * @param poolId The ID of the staking pool to stake tokens for
     * @param amount The amount of tokens to stake
     * @param user The address of the user to stake tokens for
     */
    function stakeFor(uint256 poolId, uint256 amount, address user) external;

    /**
     * @notice Unstake tokens on behalf of a user
     * @dev Unstakes tokens on behalf of the specified user for the specified staking pool
     * @param poolId The ID of the staking pool to unstake tokens for
     * @param amount The amount of tokens to unstake
     * @param user The address of the user to unstake tokens for
     */
    function unstakeFor(uint256 poolId, uint256 amount, address user) external;

    /**
     * @notice Redeem rewards for a user and pool ID
     * @dev Redeems rewards for the specified user and pool ID
     * @param poolId The ID of the staking pool to redeem rewards from
     * @param user The address of the user to redeem rewards for
     */
    function redeemRewardsByAddress(uint256 poolId, address user) external;
}