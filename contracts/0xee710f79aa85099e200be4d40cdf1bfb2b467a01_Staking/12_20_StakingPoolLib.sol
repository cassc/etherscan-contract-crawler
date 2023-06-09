// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {SafeCast} from "./SafeCast.sol";

library StakingPoolLib {
    using SafeCast for uint256;

    /// @notice This event is emitted when the staking pool is opened for stakers
    event PoolOpened();
    /// @notice This event is emitted when the staking pool's maximum size is
    /// increased
    /// @param maxPoolSize the new maximum pool size
    event PoolSizeIncreased(uint256 maxPoolSize);
    /// @notice This event is emitted when the maximum stake amount
    // for community stakers is increased
    /// @param maxStakeAmount the new maximum stake amount
    event MaxCommunityStakeAmountIncreased(uint256 maxStakeAmount);
    /// @notice This event is emitted when an operator is added
    /// @param operator address of the operator that was added to the staking pool
    event OperatorAdded(address operator);

    /// @notice Surfaces the required pool status to perform an operation
    /// (true if open / false if closed)
    /// @param currentStatus current status of the pool
    /// @param requiredStatus required status of the pool to proceed
    error InvalidPoolStatus(bool currentStatus, bool requiredStatus);
    /// @notice This error is raised when attempting to decrease maximum pool size.
    /// @param maxPoolSize the current maximum pool size
    error InvalidPoolSize(uint256 maxPoolSize);
    /// @notice This error is raised when attempting to decrease maximum stake amount
    /// for community stakers or node operators
    /// @param maxStakeAmount the current maximum stake amount
    error InvalidMaxStakeAmount(uint256 maxStakeAmount);
    /// @param requiredAmount minimum required stake amount
    error InsufficientStakeAmount(uint256 requiredAmount);
    /// @notice This error is raised when stakers attempt to stake past pool limits.
    /// @param remainingAmount maximum remaining amount that can be staked. This is
    /// the difference between the existing staked amount and the individual and global limits.
    error ExcessiveStakeAmount(uint256 remainingAmount);
    /// @notice This error is raised when stakers attempt to exit the pool.
    /// @param staker address of the staker who attempted to withdraw funds
    error StakeNotFound(address staker);
    /// @notice This error is raised when addresses with existing stake is added as an operator.
    /// @param staker address of the staker who is being added as an operator
    error ExistingStakeFound(address staker);
    /// @notice This error is raised when an address is duplicated in the supplied list of operators.
    /// This can happen in addOperators and setFeedOperators functions.
    /// @param operator address of the operator
    error OperatorAlreadyExists(address operator);
    /// @notice This error is raised when lock/unlock/slash is called on an operator that does not exist.
    /// @param operator address of the operator
    error OperatorDoesNotExist(address operator);
    /// @notice This error is raised when attempting to claim rewards by an operator.
    error NoBaseRewardForOperator();
    /// @notice This error is raised when attempting to start staking with less
    /// than the minimum required node operators
    /// @param currentOperatorsCount The current number of operators in the staking pool
    /// @param minInitialOperatorsCount The minimum required number of operators
    /// in the staking pool before opening
    error InadequateInitialOperatorsCount(uint256 currentOperatorsCount, uint256 minInitialOperatorsCount);
    /// @notice This error is raised when attempting to unstake with more than the current staking amount.
    error InadequateStakingAmount(uint256 currentStakingAmount);
    /// @notice This error is raised when attempting to claim frozen principal that does not exist.
    error FrozenPrincipalDoesNotExist(address staker);
    /// @notice This error is raised when attempting to unstake with zero amount.
    error UnstakeWithZeroAmount(address staker);
    /// @notice This error is raised when attempting to unstake with partial amount by an operator.
    error UnstakeOperatorWithPartialAmount(address operator);
    /// @notice This error is raised when attempting to unstake with existing locked staking amount.
    error ExistingLockedStakeFound(address operator);

    struct PoolLimits {
        // The max amount of staked ARPA by community stakers allowed in the pool
        uint96 maxPoolSize;
        // The max amount of ARPA a community staker can stake
        uint96 maxCommunityStakeAmount;
    }

    struct PoolState {
        // Flag that signals if the staking pool is open for staking
        bool isOpen;
        // Total number of operators added to the staking pool
        uint8 operatorsCount;
        // Total amount of ARPA staked by community stakers
        uint96 totalCommunityStakedAmount;
        // Total amount of ARPA staked by operators
        uint96 totalOperatorStakedAmount;
    }

    struct FrozenPrincipal {
        // Amount of ARPA frozen after unstaking
        uint96 amount;
        // Timestamp when the principal is unlocked
        uint256 unlockTimestamp;
    }

    struct Staker {
        // Flag that signals whether a staker is an operator
        bool isOperator;
        // Amount of ARPA staked by a staker
        uint96 stakedAmount;
        // Frozen principals of a staker
        FrozenPrincipal[] frozenPrincipals;
        // Locked staking amount of an operator
        uint96 lockedStakeAmount;
    }

    struct Pool {
        mapping(address => Staker) stakers;
        PoolState state;
        PoolLimits limits;
        // Sum of frozen principals that have not been withdrawn.
        // Used to make sure that contract's balance is correct.
        // total staked amount + total frozen amount + available rewards = current balance
        uint256 totalFrozenAmount;
    }

    /// @notice Sets staking pool parameters
    /// @param maxPoolSize Maximum total stake amount across all stakers
    /// @param maxCommunityStakeAmount Maximum stake amount for a single community staker
    function _setConfig(Pool storage pool, uint256 maxPoolSize, uint256 maxCommunityStakeAmount) internal {
        if (pool.limits.maxPoolSize > maxPoolSize) {
            revert InvalidPoolSize(maxPoolSize);
        }
        if (pool.limits.maxCommunityStakeAmount > maxCommunityStakeAmount) {
            revert InvalidMaxStakeAmount(maxCommunityStakeAmount);
        }

        if (pool.limits.maxPoolSize != maxPoolSize) {
            pool.limits.maxPoolSize = maxPoolSize._toUint96();
            emit PoolSizeIncreased(maxPoolSize);
        }
        if (pool.limits.maxCommunityStakeAmount != maxCommunityStakeAmount) {
            pool.limits.maxCommunityStakeAmount = maxCommunityStakeAmount._toUint96();
            emit MaxCommunityStakeAmountIncreased(maxCommunityStakeAmount);
        }
    }

    /// @notice Opens the staking pool
    function _open(Pool storage pool, uint256 minInitialOperatorCount) internal {
        if (uint256(pool.state.operatorsCount) < minInitialOperatorCount) {
            revert InadequateInitialOperatorsCount(pool.state.operatorsCount, minInitialOperatorCount);
        }
        pool.state.isOpen = true;
        emit PoolOpened();
    }

    /// @notice Returns true if a supplied staker address is in the operators list
    /// @param staker Address of a staker
    /// @return bool
    function _isOperator(Pool storage pool, address staker) internal view returns (bool) {
        return pool.stakers[staker].isOperator;
    }

    /// @notice Returns the sum of all principal staked in the pool
    /// @return totalStakedAmount
    function _getTotalStakedAmount(Pool storage pool) internal view returns (uint256) {
        StakingPoolLib.PoolState memory poolState = pool.state;
        return uint256(poolState.totalCommunityStakedAmount) + uint256(poolState.totalOperatorStakedAmount);
    }

    /// @notice Returns the amount of remaining space available in the pool for
    /// community stakers. Community stakers can only stake up to this amount
    /// even if they are within their individual limits.
    /// @return remainingPoolSpace
    function _getRemainingPoolSpace(Pool storage pool) internal view returns (uint256) {
        StakingPoolLib.PoolState memory poolState = pool.state;
        return uint256(pool.limits.maxPoolSize) - uint256(poolState.totalCommunityStakedAmount);
    }

    /// @dev Required conditions for adding operators:
    /// - Operators can only been added to the pool if they have no prior stake.
    /// - Operators cannot be added to the pool after staking ends.
    function _addOperators(Pool storage pool, address[] calldata operators) internal {
        for (uint256 i; i < operators.length; i++) {
            if (pool.stakers[operators[i]].isOperator) {
                revert OperatorAlreadyExists(operators[i]);
            }
            if (pool.stakers[operators[i]].stakedAmount > 0) {
                revert ExistingStakeFound(operators[i]);
            }
            pool.stakers[operators[i]].isOperator = true;
            emit OperatorAdded(operators[i]);
        }

        // Safely update operators count with respect to the maximum of 255 operators
        pool.state.operatorsCount = pool.state.operatorsCount + operators.length._toUint8();
    }
}