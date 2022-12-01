// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {SafeCast} from './SafeCast.sol';

library StakingPoolLib {
  using SafeCast for uint256;

  /// @notice This event is emitted when the staking pool is opened for stakers
  event PoolOpened();
  /// @notice This event is emitted when the staking pool is concluded
  event PoolConcluded();
  /// @notice This event is emitted when the staking pool's maximum size is
  /// increased
  /// @param maxPoolSize the new maximum pool size
  event PoolSizeIncreased(uint256 maxPoolSize);
  /// @notice This event is emitted when the maximum stake amount
  // for community stakers is increased
  /// @param maxStakeAmount the new maximum stake amount
  event MaxCommunityStakeAmountIncreased(uint256 maxStakeAmount);
  /// @notice This event is emitted when the maximum stake amount for node
  /// operators is increased
  /// @param maxStakeAmount the new maximum stake amount
  event MaxOperatorStakeAmountIncreased(uint256 maxStakeAmount);
  /// @notice This event is emitted when an operator is added
  /// @param operator address of the operator that was added to the staking pool
  event OperatorAdded(address operator);
  /// @notice This event is emitted when an operator is removed
  /// @param operator address of the operator that was removed from the staking pool
  /// @param amount principal amount that will be available for withdrawal when staking ends
  event OperatorRemoved(address operator, uint256 amount);
  /// @notice This event is emitted when the contract owner sets the list
  /// of feed operators subject to slashing
  /// @param feedOperators new list of feed operator staking addresses
  event FeedOperatorsSet(address[] feedOperators);
  /// @notice Surfaces the required pool status to perform an operation
  /// @param currentStatus current status of the pool (true if open / false if closed)
  /// @param requiredStatus required status of the pool to proceed
  /// (true if pool must be open / false if pool must be closed)
  error InvalidPoolStatus(bool currentStatus, bool requiredStatus);
  /// @notice This error is raised when attempting to decrease maximum pool size
  /// @param maxPoolSize the current maximum pool size
  error InvalidPoolSize(uint256 maxPoolSize);
  /// @notice This error is raised when attempting to decrease maximum stake amount
  /// for community stakers or node operators
  /// @param maxStakeAmount the current maximum stake amount
  error InvalidMaxStakeAmount(uint256 maxStakeAmount);
  /// @notice This error is raised when attempting to add more node operators without
  /// sufficient available pool space to reserve their allocations.
  /// @param remainingPoolSize the remaining pool space available to reserve
  /// @param requiredPoolSize the required reserved pool space to add new node operators
  error InsufficientRemainingPoolSpace(
    uint256 remainingPoolSize,
    uint256 requiredPoolSize
  );
  /// @param requiredAmount minimum required stake amount
  error InsufficientStakeAmount(uint256 requiredAmount);
  /// @notice This error is raised when stakers attempt to stake past pool limits
  /// @param remainingAmount maximum remaining amount that can be staked. This is
  /// the difference between the existing staked amount and the individual and global limits.
  error ExcessiveStakeAmount(uint256 remainingAmount);
  /// @notice This error is raised when stakers attempt to exit the pool
  /// @param staker address of the staker who attempted to withdraw funds
  error StakeNotFound(address staker);
  /// @notice This error is raised when addresses with existing stake is added as an operator
  /// @param staker address of the staker who is being added as an operator
  error ExistingStakeFound(address staker);
  /// @notice This error is raised when an address is duplicated in the supplied list of operators.
  /// This can happen in addOperators and setFeedOperators functions.
  /// @param operator address of the operator
  error OperatorAlreadyExists(address operator);
  /// @notice This error is thrown when the owner attempts to remove an on-feed operator.
  /// @dev The owner must remove the operator from the on-feed list first.
  error OperatorIsAssignedToFeed(address operator);
  /// @notice This error is raised when removing an operator in removeOperators
  /// and setFeedOperators
  /// @param operator address of the operator
  error OperatorDoesNotExist(address operator);
  /// @notice This error is raised when operator has been removed from the pool
  /// and is attempted to be readded
  /// @param operator address of the locked operator
  error OperatorIsLocked(address operator);
  /// @notice This error is raised when attempting to start staking with less
  /// than the minimum required node operators
  /// @param currentOperatorsCount The current number of operators in the staking pool
  /// @param minInitialOperatorsCount The minimum required number of operators
  /// in the staking pool before opening
  error InadequateInitialOperatorsCount(
    uint256 currentOperatorsCount,
    uint256 minInitialOperatorsCount
  );

  struct PoolLimits {
    // The max amount of staked LINK allowed in the pool
    uint96 maxPoolSize;
    // The max amount of LINK a community staker can stake
    uint80 maxCommunityStakeAmount;
    // The max amount of LINK a Node Op can stake
    uint80 maxOperatorStakeAmount;
  }

  struct PoolState {
    // Flag that signals if the staking pool is open for staking
    bool isOpen;
    // Total number of operators added to the staking pool
    uint8 operatorsCount;
    // Total amount of LINK staked by community stakers
    uint96 totalCommunityStakedAmount;
    // Total amount of LINK staked by operators
    uint96 totalOperatorStakedAmount;
  }

  struct Staker {
    // Flag that signals whether a staker is an operator
    bool isOperator;
    // Flag that signals whether a staker is an on-feed operator
    bool isFeedOperator;
    // Amount of LINK staked by a staker
    uint96 stakedAmount;
    // Amount of LINK staked by a removed operator that can be withdrawn
    // Removed operators can only withdraw at the end of staking.
    // Used to know which operators have been removed.
    uint96 removedStakeAmount;
  }

  struct Pool {
    mapping(address => Staker) stakers;
    address[] feedOperators;
    PoolState state;
    PoolLimits limits;
    // Sum of removed operator principals that have not been withdrawn.
    // Used to make sure that contract's balance is correct.
    // total staked amount + total removed amount + available rewards = current balance
    uint256 totalOperatorRemovedAmount;
  }

  /// @notice Sets staking pool parameters
  /// @param maxPoolSize Maximum total stake amount across all stakers
  /// @param maxCommunityStakeAmount Maximum stake amount for a single community staker
  /// @param maxOperatorStakeAmount Maximum stake amount for a single node operator
  function _setConfig(
    Pool storage pool,
    uint256 maxPoolSize,
    uint256 maxCommunityStakeAmount,
    uint256 maxOperatorStakeAmount
  ) internal {
    if (maxOperatorStakeAmount > maxPoolSize)
      revert InvalidMaxStakeAmount(maxOperatorStakeAmount);

    if (pool.limits.maxPoolSize > maxPoolSize)
      revert InvalidPoolSize(maxPoolSize);
    if (pool.limits.maxCommunityStakeAmount > maxCommunityStakeAmount)
      revert InvalidMaxStakeAmount(maxCommunityStakeAmount);
    if (pool.limits.maxOperatorStakeAmount > maxOperatorStakeAmount)
      revert InvalidMaxStakeAmount(maxOperatorStakeAmount);

    PoolState memory poolState = pool.state;
    if (
      maxPoolSize <
      (poolState.operatorsCount * maxOperatorStakeAmount) +
        poolState.totalCommunityStakedAmount
    ) revert InvalidMaxStakeAmount(maxOperatorStakeAmount);
    if (pool.limits.maxPoolSize != maxPoolSize) {
      pool.limits.maxPoolSize = maxPoolSize._toUint96();
      emit PoolSizeIncreased(maxPoolSize);
    }
    if (pool.limits.maxCommunityStakeAmount != maxCommunityStakeAmount) {
      pool.limits.maxCommunityStakeAmount = maxCommunityStakeAmount._toUint80();
      emit MaxCommunityStakeAmountIncreased(maxCommunityStakeAmount);
    }
    if (pool.limits.maxOperatorStakeAmount != maxOperatorStakeAmount) {
      pool.limits.maxOperatorStakeAmount = maxOperatorStakeAmount._toUint80();
      emit MaxOperatorStakeAmountIncreased(maxOperatorStakeAmount);
    }
  }

  /// @notice Opens the staking pool
  function _open(Pool storage pool, uint256 minInitialOperatorCount) internal {
    if (uint256(pool.state.operatorsCount) < minInitialOperatorCount)
      revert InadequateInitialOperatorsCount(
        pool.state.operatorsCount,
        minInitialOperatorCount
      );
    pool.state.isOpen = true;
    emit PoolOpened();
  }

  /// @notice Closes the staking pool
  function _close(Pool storage pool) internal {
    pool.state.isOpen = false;
    emit PoolConcluded();
  }

  /// @notice Returns true if a supplied staker address is in the operators list
  /// @param staker Address of a staker
  /// @return bool
  function _isOperator(Pool storage pool, address staker)
    internal
    view
    returns (bool)
  {
    return pool.stakers[staker].isOperator;
  }

  /// @notice Returns the sum of all principal staked in the pool
  /// @return totalStakedAmount
  function _getTotalStakedAmount(Pool storage pool)
    internal
    view
    returns (uint256)
  {
    StakingPoolLib.PoolState memory poolState = pool.state;
    return
      uint256(poolState.totalCommunityStakedAmount) +
      uint256(poolState.totalOperatorStakedAmount);
  }

  /// @notice Returns the amount of remaining space available in the pool for
  /// community stakers. Community stakers can only stake up to this amount
  /// even if they are within their individual limits.
  /// @return remainingPoolSpace
  function _getRemainingPoolSpace(Pool storage pool)
    internal
    view
    returns (uint256)
  {
    StakingPoolLib.PoolState memory poolState = pool.state;
    return
      uint256(pool.limits.maxPoolSize) -
      (uint256(poolState.operatorsCount) *
        uint256(pool.limits.maxOperatorStakeAmount)) -
      uint256(poolState.totalCommunityStakedAmount);
  }

  /// @dev Required conditions for adding operators:
  /// - Operators can only been added to the pool if they have no prior stake.
  /// - Operators can only been readded to the pool if they have no removed
  /// stake.
  /// - Operators cannot be added to the pool after staking ends (either through
  /// conclusion or through reward expiry).
  function _addOperators(Pool storage pool, address[] calldata operators)
    internal
  {
    uint256 requiredReservedPoolSpace = operators.length *
      uint256(pool.limits.maxOperatorStakeAmount);
    uint256 remainingPoolSpace = _getRemainingPoolSpace(pool);
    if (requiredReservedPoolSpace > remainingPoolSpace)
      revert InsufficientRemainingPoolSpace(
        remainingPoolSpace,
        requiredReservedPoolSpace
      );

    for (uint256 i; i < operators.length; i++) {
      if (pool.stakers[operators[i]].isOperator)
        revert OperatorAlreadyExists(operators[i]);
      if (pool.stakers[operators[i]].stakedAmount > 0)
        revert ExistingStakeFound(operators[i]);
      // Avoid edge-cases where we attempt to add an operator that has
      // locked principal (this means that the operator was previously removed).
      if (pool.stakers[operators[i]].removedStakeAmount > 0)
        revert OperatorIsLocked(operators[i]);
      pool.stakers[operators[i]].isOperator = true;
      emit OperatorAdded(operators[i]);
    }

    // Safely update operators count with respect to the maximum of 255 operators
    pool.state.operatorsCount =
      pool.state.operatorsCount +
      operators.length._toUint8();
  }

  /// @notice Helper function to set the list of on-feed Operator addresses
  /// @param operators List of Operator addresses
  function _setFeedOperators(Pool storage pool, address[] calldata operators)
    internal
  {
    for (uint256 i; i < pool.feedOperators.length; i++) {
      delete pool.stakers[pool.feedOperators[i]].isFeedOperator;
    }
    delete pool.feedOperators;

    for (uint256 i; i < operators.length; i++) {
      address newFeedOperator = operators[i];
      if (!_isOperator(pool, newFeedOperator))
        revert OperatorDoesNotExist(newFeedOperator);
      if (pool.stakers[newFeedOperator].isFeedOperator)
        revert OperatorAlreadyExists(newFeedOperator);

      pool.stakers[newFeedOperator].isFeedOperator = true;
    }
    pool.feedOperators = operators;

    emit FeedOperatorsSet(operators);
  }
}