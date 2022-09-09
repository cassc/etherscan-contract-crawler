// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Enjinstarter
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./IAdminWallet.sol";

/**
 * @title StakingService Interface
 * @author Tim Loh
 * @notice Interface for StakingService which provides staking functionalities
 */
interface IStakingService is IAccessControl, IAdminWallet {
    /**
     * @notice Emitted when revoked stakes have been removed from pool
     * @param poolId The staking pool identifier
     * @param sender The address that withdrew the revoked stakes to admin wallet
     * @param adminWallet The address of the admin wallet receiving the funds
     * @param stakeToken The address of the transferred ERC20 token
     * @param stakeAmountWei The amount of tokens transferred in Wei
     */
    event RevokedStakesRemoved(
        bytes32 indexed poolId,
        address indexed sender,
        address indexed adminWallet,
        address stakeToken,
        uint256 stakeAmountWei
    );

    /**
     * @notice Emitted when reward has been claimed by user
     * @param poolId The staking pool identifier
     * @param account The address of the user wallet receiving funds
     * @param rewardToken The address of the transferred ERC20 token
     * @param rewardWei The amount of tokens transferred in Wei
     */
    event RewardClaimed(
        bytes32 indexed poolId,
        address indexed account,
        address indexed rewardToken,
        uint256 rewardWei
    );

    /**
     * @notice Emitted when stake has been placed by user
     * @param poolId The staking pool identifier
     * @param account The address of the user wallet that placed the stake
     * @param stakeToken The address of the ERC20 stake token
     * @param stakeAmountWei The amount of tokens staked in Wei
     * @param stakeTimestamp The timestamp as seconds since unix epoch when the stake was placed
     * @param stakeMaturityTimestamp The timestamp as seconds since unix epoch when the stake matures
     * @param rewardAtMaturityWei The expected reward in Wei at maturity
     */
    event Staked(
        bytes32 indexed poolId,
        address indexed account,
        address indexed stakeToken,
        uint256 stakeAmountWei,
        uint256 stakeTimestamp,
        uint256 stakeMaturityTimestamp,
        uint256 rewardAtMaturityWei
    );

    /**
     * @notice Emitted when user stake has been resumed
     * @param poolId The staking pool identifier
     * @param sender The address that resumed the stake
     * @param account The address of the user wallet whose stake has been resumed
     */
    event StakeResumed(
        bytes32 indexed poolId,
        address indexed sender,
        address indexed account
    );

    /**
     * @notice Emitted when user stake with reward has been revoked
     * @param poolId The staking pool identifier
     * @param sender The address that revoked the user stake
     * @param account The address of the user wallet whose stake has been revoked
     * @param stakeToken The address of the ERC20 stake token
     * @param stakeAmountWei The amount of tokens staked in Wei
     * @param rewardToken The address of the ERC20 reward token
     * @param rewardWei The expected reward in Wei
     */
    event StakeRevoked(
        bytes32 indexed poolId,
        address indexed sender,
        address indexed account,
        address stakeToken,
        uint256 stakeAmountWei,
        address rewardToken,
        uint256 rewardWei
    );

    /**
     * @notice Emitted when user stake has been suspended
     * @param poolId The staking pool identifier
     * @param sender The address that suspended the user stake
     * @param account The address of the user wallet whose stake has been suspended
     */
    event StakeSuspended(
        bytes32 indexed poolId,
        address indexed sender,
        address indexed account
    );

    /**
     * @notice Emitted when staking pool contract has been changed
     * @param oldStakingPool The address of the staking pool contract before the staking pool was changed
     * @param newStakingPool The address pf the staking pool contract after the staking pool was changed
     * @param sender The address that changed the staking pool contract
     */
    event StakingPoolContractChanged(
        address indexed oldStakingPool,
        address indexed newStakingPool,
        address indexed sender
    );

    /**
     * @notice Emitted when reward has been added to staking pool
     * @param poolId The staking pool identifier
     * @param sender The address that added the reward
     * @param rewardToken The address of the ERC20 reward token
     * @param rewardAmountWei The amount of reward tokens added in Wei
     */
    event StakingPoolRewardAdded(
        bytes32 indexed poolId,
        address indexed sender,
        address indexed rewardToken,
        uint256 rewardAmountWei
    );

    /**
     * @notice Emitted when unallocated reward has been removed from staking pool
     * @param poolId The staking pool identifier
     * @param sender The address that removed the unallocated reward
     * @param adminWallet The address of the admin wallet receiving the funds
     * @param rewardToken The address of the ERC20 reward token
     * @param rewardAmountWei The amount of reward tokens removed in Wei
     */
    event StakingPoolRewardRemoved(
        bytes32 indexed poolId,
        address indexed sender,
        address indexed adminWallet,
        address rewardToken,
        uint256 rewardAmountWei
    );

    /**
     * @notice Emitted when stake with reward has been withdrawn by user
     * @param poolId The staking pool identifier
     * @param account The address of the user wallet that unstaked and received the funds
     * @param stakeToken The address of the ERC20 stake token
     * @param unstakeAmountWei The amount of stake tokens unstaked in Wei
     * @param rewardToken The address of the ERC20 reward token
     * @param rewardWei The amount of reward tokens claimed in Wei
     */
    event Unstaked(
        bytes32 indexed poolId,
        address indexed account,
        address indexed stakeToken,
        uint256 unstakeAmountWei,
        address rewardToken,
        uint256 rewardWei
    );

    /**
     * @notice Claim reward from given staking pool for message sender
     * @param poolId The staking pool identifier
     */
    function claimReward(bytes32 poolId) external;

    /**
     * @notice Stake given amount in given staking pool for message sender
     * @dev Requires the user to have approved the transfer of stake amount to this contract.
     *      User can increase an existing stake that has not matured yet but stake maturity date will
     *      be reset while rewards earned up to the point where stake is increased will be accumulated.
     * @param poolId The staking pool identifier
     * @param stakeAmountWei The amount of tokens to stake in Wei
     */
    function stake(bytes32 poolId, uint256 stakeAmountWei) external;

    /**
     * @notice Unstake with claim reward from given staking pool for message sender
     * @param poolId The staking pool identifier
     */
    function unstake(bytes32 poolId) external;

    /**
     * @notice Add reward to given staking pool
     * @dev Must be called by contract admin role.
     *      Requires the admin user to have approved the transfer of reward amount to this contract.
     * @param poolId The staking pool identifier
     * @param rewardAmountWei The amount of reward tokens to add in Wei
     */
    function addStakingPoolReward(bytes32 poolId, uint256 rewardAmountWei)
        external;

    /**
     * @notice Withdraw revoked stakes from given staking pool to admin wallet
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     */
    function removeRevokedStakes(bytes32 poolId) external;

    /**
     * @notice Withdraw unallocated reward from given staking pool to admin wallet
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     */
    function removeUnallocatedStakingPoolReward(bytes32 poolId) external;

    /**
     * @notice Resume stake for given staking pool and account
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     * @param account The address of the user wallet that staked
     */
    function resumeStake(bytes32 poolId, address account) external;

    /**
     * @notice Revoke stake for given staking pool and account
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     * @param account The address of the user wallet that staked
     */
    function revokeStake(bytes32 poolId, address account) external;

    /**
     * @notice Suspend stake for given staking pool and account
     * @dev Must be called by contract admin role
     * @param poolId The staking pool identifier
     * @param account The address of the user wallet that staked
     */
    function suspendStake(bytes32 poolId, address account) external;

    /**
     * @notice Pause user functions (stake, claimReward, unstake)
     * @dev Must be called by governance role
     */
    function pauseContract() external;

    /**
     * @notice Change admin wallet to a new wallet address
     * @dev Must be called by governance role
     * @param newWallet The new admin wallet
     */
    function setAdminWallet(address newWallet) external;

    /**
     * @notice Change staking pool contract to a new contract address
     * @dev Must be called by governance role
     * @param newStakingPool The new staking pool contract address
     */
    function setStakingPoolContract(address newStakingPool) external;

    /**
     * @notice Unpause user functions (stake, claimReward, unstake)
     * @dev Must be called by governance role
     */
    function unpauseContract() external;

    /**
     * @notice Returns the claimable reward in Wei for given staking pool and account
     * @param poolId The staking pool identifier
     * @param account The address of the user wallet that staked
     * @return Claimable reward in Wei
     */
    function getClaimableRewardWei(bytes32 poolId, address account)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the stake info for given staking pool and account
     * @param poolId The staking pool identifier
     * @param account The address of the user wallet that staked
     * @return stakeAmountWei The amount of tokens staked in Wei
     * @return stakeTimestamp The timestamp as seconds since unix epoch when the stake was placed
     * @return stakeMaturityTimestamp The timestamp as seconds since unix epoch when the stake matures
     * @return estimatedRewardAtMaturityWei The estimated reward in Wei at maturity
     * @return rewardClaimedWei The reward in Wei that has already been claimed
     * @return isActive True if stake has not been suspended
     */
    function getStakeInfo(bytes32 poolId, address account)
        external
        view
        returns (
            uint256 stakeAmountWei,
            uint256 stakeTimestamp,
            uint256 stakeMaturityTimestamp,
            uint256 estimatedRewardAtMaturityWei,
            uint256 rewardClaimedWei,
            bool isActive
        );

    /**
     * @notice Returns the staking pool statistics for given staking pool
     * @param poolId The staking pool identifier
     * @return totalRewardWei The total amount of staking pool reward in Wei
     * @return totalStakedWei The total amount of stakes inside staking pool in Wei
     * @return rewardToBeDistributedWei The total amount of allocated staking pool reward to be distributed in Wei
     * @return totalRevokedStakeWei The total amount of revoked stakes in Wei
     * @return poolSizeWei The pool size in Wei
     * @return isOpen True if staking pool is open to accept user stakes
     * @return isActive True if user is allowed to claim reward and unstake from staking pool
     */
    function getStakingPoolStats(bytes32 poolId)
        external
        view
        returns (
            uint256 totalRewardWei,
            uint256 totalStakedWei,
            uint256 rewardToBeDistributedWei,
            uint256 totalRevokedStakeWei,
            uint256 poolSizeWei,
            bool isOpen,
            bool isActive
        );

    /**
     * @notice Returns the staking pool contract address
     * @return Staking pool contract address
     */
    function stakingPoolContract() external view returns (address);
}