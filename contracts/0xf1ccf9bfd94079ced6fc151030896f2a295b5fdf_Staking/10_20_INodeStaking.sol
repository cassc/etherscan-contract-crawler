// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface INodeStaking {
    /// @notice This event is emitted when a node locks stake in the pool.
    /// @param staker Staker address
    /// @param newLock New principal amount locked
    event Locked(address staker, uint256 newLock);

    /// @notice This event is emitted when a node unlocks stake in the pool.
    /// @param staker Staker address
    /// @param newUnlock New principal amount unlocked
    event Unlocked(address staker, uint256 newUnlock);

    /// @notice This event is emitted when a node gets delegation reward slashed.
    /// @param staker Staker address
    /// @param amount Amount slashed
    event DelegationRewardSlashed(address staker, uint256 amount);

    /// @notice This error is raised when attempting to unlock with more than the current locked staking amount
    /// @param currentLockedStakingAmount Current locked staking amount
    error InadequateOperatorLockedStakingAmount(uint256 currentLockedStakingAmount);

    /// @notice This function allows controller to lock staking amount for a node.
    /// @param staker Node address
    /// @param amount Amount to lock
    function lock(address staker, uint256 amount) external;

    /// @notice This function allows controller to unlock staking amount for a node.
    /// @param staker Node address
    /// @param amount Amount to unlock
    function unlock(address staker, uint256 amount) external;

    /// @notice This function allows controller to slash delegation reward of a node.
    /// @param staker Node address
    /// @param amount Amount to slash
    function slashDelegationReward(address staker, uint256 amount) external;

    /// @notice This function returns the locked amount of a node.
    /// @param staker Node address
    function getLockedAmount(address staker) external view returns (uint256);
}