// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Enjinstarter
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title StakingPool Interface
 * @author Tim Loh
 * @notice Interface for StakingPool which contains the staking pool configs used by StakingService
 */
interface IStakingPool is IAccessControl {
    /**
     * @notice Emitted when a staking pool has been closed
     * @param poolId The staking pool identifier
     * @param sender The address that closed the staking pool
     */
    event StakingPoolClosed(bytes32 indexed poolId, address indexed sender);

    /**
     * @notice Emitted when a staking pool has been created
     * @param poolId The staking pool identifier
     * @param sender The address that created the staking pool
     * @param stakeDurationDays The duration in days that user stakes will be locked in staking pool
     * @param stakeTokenAddress The address of the ERC20 stake token for staking pool
     * @param stakeTokenDecimals The ERC20 stake token decimal places
     * @param rewardTokenAddress The address of the ERC20 reward token for staking pool
     * @param rewardTokenDecimals The ERC20 reward token decimal places
     * @param poolAprWei The APR (Annual Percentage Rate) in Wei for staking pool
     */
    event StakingPoolCreated(
        bytes32 indexed poolId,
        address indexed sender,
        uint256 indexed stakeDurationDays,
        address stakeTokenAddress,
        uint256 stakeTokenDecimals,
        address rewardTokenAddress,
        uint256 rewardTokenDecimals,
        uint256 poolAprWei
    );

    /**
     * @notice Emitted when a staking pool has been opened
     * @param poolId The staking pool identifier
     * @param sender The address that opened the staking pool
     */
    event StakingPoolOpened(bytes32 indexed poolId, address indexed sender);

    /**
     * @notice Emitted when a staking pool has been resumed
     * @param poolId The staking pool identifier
     * @param sender The address that resumed the staking pool
     */
    event StakingPoolResumed(bytes32 indexed poolId, address indexed sender);

    /**
     * @notice Emitted when a staking pool has been suspended
     * @param poolId The staking pool identifier
     * @param sender The address that suspended the staking pool
     */
    event StakingPoolSuspended(bytes32 indexed poolId, address indexed sender);

    /**
     * @notice Closes the given staking pool to reject user stakes
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     */
    function closeStakingPool(bytes32 poolId) external;

    /**
     * @notice Creates a staking pool for the given pool identifier and config
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     * @param stakeDurationDays The duration in days that user stakes will be locked in staking pool
     * @param stakeTokenAddress The address of the ERC20 stake token for staking pool
     * @param stakeTokenDecimals The ERC20 stake token decimal places
     * @param rewardTokenAddress The address of the ERC20 reward token for staking pool
     * @param rewardTokenDecimals The ERC20 reward token decimal places
     * @param poolAprWei The APR (Annual Percentage Rate) in Wei for staking pool
     */
    function createStakingPool(
        bytes32 poolId,
        uint256 stakeDurationDays,
        address stakeTokenAddress,
        uint256 stakeTokenDecimals,
        address rewardTokenAddress,
        uint256 rewardTokenDecimals,
        uint256 poolAprWei
    ) external;

    /**
     * @notice Opens the given staking pool to accept user stakes
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     */
    function openStakingPool(bytes32 poolId) external;

    /**
     * @notice Resumes the given staking pool to allow user reward claims and unstakes
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     */
    function resumeStakingPool(bytes32 poolId) external;

    /**
     * @notice Suspends the given staking pool to prevent user reward claims and unstakes
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     */
    function suspendStakingPool(bytes32 poolId) external;

    /**
     * @notice Returns the given staking pool info
     * @param poolId The staking pool identifier
     * @return stakeDurationDays The duration in days that user stakes will be locked in staking pool
     * @return stakeTokenAddress The address of the ERC20 stake token for staking pool
     * @return stakeTokenDecimals The ERC20 stake token decimal places
     * @return rewardTokenAddress The address of the ERC20 reward token for staking pool
     * @return rewardTokenDecimals The ERC20 reward token decimal places
     * @return poolAprWei The APR (Annual Percentage Rate) in Wei for staking pool
     * @return isOpen True if staking pool is open to accept user stakes
     * @return isActive True if user is allowed to claim reward and unstake from staking pool
     */
    function getStakingPoolInfo(bytes32 poolId)
        external
        view
        returns (
            uint256 stakeDurationDays,
            address stakeTokenAddress,
            uint256 stakeTokenDecimals,
            address rewardTokenAddress,
            uint256 rewardTokenDecimals,
            uint256 poolAprWei,
            bool isOpen,
            bool isActive
        );
}