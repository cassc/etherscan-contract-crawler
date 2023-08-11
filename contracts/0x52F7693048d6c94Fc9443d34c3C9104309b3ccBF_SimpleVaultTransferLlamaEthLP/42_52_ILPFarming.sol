// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Interface to jpeg'd LPFarming Contracts
 * @dev https://github.com/jpegd/core/blob/main/contracts/farming/LPFarming.sol
 * @dev Only whitelisted contracts may call these functions
 */
interface ILPFarming {
    /// @dev Data relative to an LP pool
    /// @param lpToken The LP token accepted by the pool
    /// @param allocPoint Allocation points assigned to the pool. Determines the share of `rewardPerBlock` allocated to this pool
    /// @param lastRewardBlock Last block number in which reward distribution occurred
    /// @param accRewardPerShare Accumulated rewards per share, times 1e36. The amount of rewards the pool has accumulated per unit of LP token deposited
    /// @param depositedAmount Total number of tokens deposited in the pool.
    struct PoolInfo {
        address lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
        uint256 depositedAmount;
    }

    /// @dev Data relative to a user's staking position
    /// @param amount The amount of LP tokens the user has provided
    /// @param lastAccRewardPerShare The `accRewardPerShare` pool value at the time of the user's last claim
    struct UserInfo {
        uint256 amount;
        uint256 lastAccRewardPerShare;
    }

    /**
     * @notice getter for poolInfo struct in  PoolInfo array of JPEGd LPFarming contract
     * @param index index of poolInfo in PoolInfo array
     * @return PoolInfo[] array of PoolInfo structs
     */
    function poolInfo(uint256 index) external view returns (PoolInfo memory);

    /**
     * @notice getter for the userInfo mapping in JPEGd LPFarming contract
     * @return UserInfo userInfo struct for user in JPEGd LPFarming pool with poolId
     */
    function userInfo(
        uint256 poolId,
        address user
    ) external view returns (UserInfo memory);

    /// @notice Frontend function used to calculate the amount of rewards `_user` can claim from the pool with id `_pid`
    /// @param _pid The pool id
    /// @param _user The address of the user
    /// @return The amount of rewards claimable from `_pid` by user `_user`
    function pendingReward(
        uint256 _pid,
        address _user
    ) external view returns (uint256);

    /// @notice Allows users to deposit `_amount` of LP tokens in the pool with id `_pid`. Non whitelisted contracts can't call this function
    /// @dev Emits a {Deposit} event
    /// @param _pid The id of the pool to deposit into
    /// @param _amount The amount of LP tokens to deposit
    function deposit(uint256 _pid, uint256 _amount) external;

    /// @notice Allows users to withdraw `_amount` of LP tokens from the pool with id `_pid`. Non whitelisted contracts can't call this function
    /// @dev Emits a {Withdraw} event
    /// @param _pid The id of the pool to withdraw from
    /// @param _amount The amount of LP tokens to withdraw
    function withdraw(uint256 _pid, uint256 _amount) external;

    /// @notice Allows users to claim rewards from the pool with id `_pid`. Non whitelisted contracts can't call this function
    /// @dev Emits a {Claim} event
    /// @param _pid The pool to claim rewards from
    function claim(uint256 _pid) external;

    /// @notice Allows users to claim rewards from all pools. Non whitelisted contracts can't call this function
    /// @dev Emits a {ClaimAll} event
    function claimAll() external;
}