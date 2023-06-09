// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

interface IVestingFactory {
    /**
     * @dev Error thrown when an invalid pool share is provided
     */
    error InvalidPoolShare();

    /**
     * @dev Error thrown when pool amount exceeds the total available tokens
     */
    error PoolAmountExceeded();

    /**
     * @dev Error thrown when an invalid pool address is provided
     */
    error InvalidPoolAddress();

    /**
     * @dev Error thrown when there are insufficient token amounts
     */
    error InsufficientTokenAmounts();

    /**
     * @dev Stores information about each vesting pool.
     * @param poolShare The percentage share of the pool.
     * @param poolAmount The amount of tokens in the pool.
     * @param poolName The name of the pool.
     */
    struct PoolInfo {
        uint256 poolShare;
        uint256 poolAmount;
        string poolName;
    }

    /**
     * @dev Emitted when a new vesting pool is created.
     * @param poolAddress The address of the newly created pool.
     * @param poolShare The percentage share of the pool.
     * @param poolName The name of the pool.
     */
    event PoolCreated(address indexed poolAddress, uint256 poolShare, string poolName);

    /**
     * @dev Emitted when a vesting pool is initialized.
     * @param poolAddress The address of the initialized pool.
     * @param poolShare The percentage share of the pool.
     * @param poolAmount The amount of tokens in the pool.
     */
    event PoolInitialized(address indexed poolAddress, uint256 poolShare, uint256 poolAmount);

    /**
     * @dev Emitted when a vesting pool is updated.
     * @param poolAddress The address of the updated pool.
     * @param poolShare The updated percentage share of the pool.
     * @param poolAmount The updated amount of tokens in the pool.
     * @param poolName The name of the pool.
     */
    event PoolUpdated(address indexed poolAddress, uint256 poolShare, uint256 poolAmount, string poolName);
}