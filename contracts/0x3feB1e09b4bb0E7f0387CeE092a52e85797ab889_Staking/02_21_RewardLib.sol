// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {SafeCast} from './SafeCast.sol';
import {StakingPoolLib} from './StakingPoolLib.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

library RewardLib {
  using SafeCast for uint256;

  /// @notice emitted when the reward is initialized for the first time
  /// @param rate the reward rate
  /// @param available the amount of rewards available for distribution in the
  /// staking pool
  /// @param startTimestamp the start timestamp when rewards are started
  /// @param endTimestamp the timestamp when the reward will run out
  event RewardInitialized(
    uint256 rate,
    uint256 available,
    uint256 startTimestamp,
    uint256 endTimestamp
  );
  /// @notice emitted when owner changes the reward rate
  /// @param rate the new reward rate
  event RewardRateChanged(uint256 rate);
  /// @notice emitted when owner adds more rewards to the pool
  /// @param amountAdded the amount of LINK rewards added to the pool
  event RewardAdded(uint256 amountAdded);
  /// @notice emitted when owner withdraws unreserved rewards
  /// @param amount the amount of rewards withdrawn
  event RewardWithdrawn(uint256 amount);
  /// @notice emitted when an on feed operator gets slashed.
  /// Node operators are not slashed more than the amount of rewards they
  /// have earned.  This means that a node operator that has not
  /// accumulated at least two weeks of rewards will be slashed
  /// less than an operator that has accumulated at least
  /// two weeks of rewards.
  event RewardSlashed(
    address[] operator,
    uint256[] slashedBaseRewards,
    uint256[] slashedDelegatedRewards
  );

  /// @notice This error is thrown when the updated reward duration is less than a month
  error RewardDurationTooShort();

  /// @notice This is the reward calculation precision variable. LINK token has the
  /// 1e18 multiplier which means that rewards are floored after 6 decimals
  /// points. Micro LINK is the smallest unit that is eligible for rewards.
  uint256 internal constant REWARD_PRECISION = 1e12;

  struct DelegatedRewards {
    // Count of delegates who are eligible for a share of a reward
    // This is always going to be less or equal to operatorsCount
    uint8 delegatesCount;
    // Tracks base reward amounts that goes to an operator as delegation rewards.
    // Used to correctly account for any changes in operator count, delegated amount, or reward rate.
    // Formula: duration * rate * amount
    uint96 cumulativePerDelegate;
    // Timestamp of the last time accumulate was called
    // `startTimestamp` <= `delegated.lastAccumulateTimestamp`
    uint32 lastAccumulateTimestamp;
  }

  struct BaseRewards {
    // Reward rate expressed in juels per second per micro LINK
    uint80 rate;
    // The cumulative LINK accrued per stake from past reward rates
    // expressed in juels per micro LINK
    // Formula: sum of (previousRate * elapsedDurationSinceLastAccumulate)
    uint96 cumulativePerMicroLINK;
    // Timestamp of the last time the base reward rate was accumulated
    uint32 lastAccumulateTimestamp;
  }

  struct MissedRewards {
    // Tracks missed base rewards that are deducted from late stakers
    uint96 base;
    // Tracks missed delegation rewards that are deducted from late delegates
    uint96 delegated;
  }

  struct ReservedRewards {
    // Tracks base reward amount reserved for stakers. This can be used after
    // `endTimestamp` to calculate unused amount.
    // This amount accumulates as the reward is utilized.
    // Formula: duration * rate * amount
    uint96 base;
    // Tracks delegated reward amount reserved for node operators. This can
    // be used after `endTimestamp` to calculate unused amount.
    // This amount accumulates as the reward is utilized.
    // Formula: duration * rate * amount
    uint96 delegated;
  }

  struct Reward {
    mapping(address => MissedRewards) missed;
    DelegatedRewards delegated;
    BaseRewards base;
    ReservedRewards reserved;
    // Timestamp when the reward stops accumulating. Has to support a very long
    // duration for scenarios with low reward rate.
    // `endTimestamp` >= `startTimestamp`
    uint256 endTimestamp;
    // Timestamp when the reward comes into effect
    // `startTimestamp` <= `endTimestamp`
    uint32 startTimestamp;
  }

  /// @notice initializes the reward with the defined parameters
  /// @param maxPoolSize maximum pool size that the reward is initialized with
  /// @param rate reward rate
  /// @param minRewardDuration the minimum duration rewards need to last for
  /// @param availableReward available reward amount
  /// @dev can only be called once. Any future reward changes have to be done
  /// using specific functions.
  function _initialize(
    Reward storage reward,
    uint256 maxPoolSize,
    uint256 rate,
    uint256 minRewardDuration,
    uint256 availableReward
  ) internal {
    if (reward.startTimestamp != 0) revert();

    reward.base.rate = rate._toUint80();

    uint32 blockTimestamp = block.timestamp._toUint32();
    reward.startTimestamp = blockTimestamp;
    reward.delegated.lastAccumulateTimestamp = blockTimestamp;
    reward.base.lastAccumulateTimestamp = blockTimestamp;

    _updateDuration(
      reward,
      maxPoolSize,
      0,
      rate,
      minRewardDuration,
      availableReward,
      0
    );

    emit RewardInitialized(
      rate,
      availableReward,
      reward.startTimestamp,
      reward.endTimestamp
    );
  }

  /// @return bool true if the reward is expired (end <= now)
  function _isDepleted(Reward storage reward) internal view returns (bool) {
    return reward.endTimestamp <= block.timestamp;
  }

  /// @notice Helper function to accumulate base rewards
  /// Accumulate reward per micro LINK before changing reward rate.
  /// This keeps rewards prior to rate change unaffected.
  function _accumulateBaseRewards(Reward storage reward) internal {
    uint256 cappedTimestamp = _getCappedTimestamp(reward);

    reward.base.cumulativePerMicroLINK += (uint256(reward.base.rate) *
      (cappedTimestamp - uint256(reward.base.lastAccumulateTimestamp)))
      ._toUint96();
    reward.base.lastAccumulateTimestamp = cappedTimestamp._toUint32();
  }

  /// @notice Helper function to accumulate delegation rewards
  /// @dev This function is necessary to correctly account for any changes in
  /// eligible operators, delegated amount or reward rate.
  function _accumulateDelegationRewards(
    Reward storage reward,
    uint256 delegatedAmount
  ) internal {
    reward.delegated.cumulativePerDelegate = _calculateAccruedDelegatedRewards(
      reward,
      delegatedAmount
    )._toUint96();

    reward.delegated.lastAccumulateTimestamp = _getCappedTimestamp(reward)
      ._toUint32();
  }

  /// @notice Helper function to calculate rewards
  /// @param amount a staked amount to calculate rewards for
  /// @param duration a duration that the specified amount receives rewards for
  /// @return rewardsAmount
  function _calculateReward(
    Reward storage reward,
    uint256 amount,
    uint256 duration
  ) internal view returns (uint256) {
    return (amount * uint256(reward.base.rate) * duration) / REWARD_PRECISION;
  }

  /// @notice Calculates the amount of delegated rewards accumulated so far.
  /// @dev This function takes into account the amount of delegated
  /// rewards accumulated from previous delegate counts and amounts and
  /// the latest additional value.
  function _calculateAccruedDelegatedRewards(
    Reward storage reward,
    uint256 totalDelegatedAmount
  ) internal view returns (uint256) {
    uint256 elapsedDurationSinceLastAccumulate = _isDepleted(reward)
      ? uint256(reward.endTimestamp) -
        uint256(reward.delegated.lastAccumulateTimestamp)
      : block.timestamp - uint256(reward.delegated.lastAccumulateTimestamp);

    return
      uint256(reward.delegated.cumulativePerDelegate) +
      _calculateReward(
        reward,
        totalDelegatedAmount,
        elapsedDurationSinceLastAccumulate
      ) /
      // We are doing this to keep track of delegated rewards prior to the
      // first operator staking.
      Math.max(uint256(reward.delegated.delegatesCount), 1);
  }

  /// @notice Calculates the amount of rewards accrued so far.
  /// @dev This function takes into account the amount of
  /// rewards accumulated from previous rates in addition to
  /// the rewards that will be accumulated based off the current rate
  /// over a given duration.
  function _calculateAccruedBaseRewards(Reward storage reward, uint256 amount)
    internal
    view
    returns (uint256)
  {
    uint256 elapsedDurationSinceLastAccumulate = _isDepleted(reward)
      ? (uint256(reward.endTimestamp) -
        uint256(reward.base.lastAccumulateTimestamp))
      : block.timestamp - uint256(reward.base.lastAccumulateTimestamp);

    return
      (amount *
        (uint256(reward.base.cumulativePerMicroLINK) +
          uint256(reward.base.rate) *
          elapsedDurationSinceLastAccumulate)) / REWARD_PRECISION;
  }

  /// @notice We use a simplified reward calculation formula because we know that
  /// the reward is expired. We accumulate reward per micro LINK
  /// before concluding the pool so we can avoid reading additional storage
  /// variables.
  function _calculateConcludedBaseRewards(
    Reward storage reward,
    uint256 amount,
    address staker
  ) internal view returns (uint256) {
    return
      (amount * uint256(reward.base.cumulativePerMicroLINK)) /
      REWARD_PRECISION -
      uint256(reward.missed[staker].base);
  }

  /// @notice Reserves staker rewards. This is necessary to make sure that
  /// there are always enough available LINK tokens for all stakers until the
  /// reward end timestamp. The amount is calculated for the remaining reward
  /// duration using the current reward rate.
  /// @param baseRewardAmount The amount of base rewards to reserve
  /// or unreserve for
  /// @param delegatedRewardAmount The amount of delegated rewards to reserve
  /// or unreserve for
  /// @param isReserving true if function should reserve more rewards. false will
  /// unreserve and deduct from the reserved total
  function _updateReservedRewards(
    Reward storage reward,
    uint256 baseRewardAmount,
    uint256 delegatedRewardAmount,
    bool isReserving
  ) private {
    uint256 duration = _getRemainingDuration(reward);
    uint96 deltaBaseReward = _calculateReward(
      reward,
      baseRewardAmount,
      duration
    )._toUint96();
    uint96 deltaDelegatedReward = _calculateReward(
      reward,
      delegatedRewardAmount,
      duration
    )._toUint96();
    // add if is reserving, subtract otherwise
    if (isReserving) {
      // We round up (by adding an extra juels) if the amount includes an
      // increment below REWARD_PRECISION. We always need to reserve more than
      // the user will earn. The consequence of this is that we’ll have dust
      // LINK amounts left over in the contract after stakers exit. The amount
      // will be approximately 1 juels for every call to reserve function,
      // which translates to <1 LINK for the duration of staking v0.1 contract.
      if (baseRewardAmount % REWARD_PRECISION > 0) deltaBaseReward++;
      if (delegatedRewardAmount % REWARD_PRECISION > 0) deltaDelegatedReward++;

      reward.reserved.base += deltaBaseReward;
      reward.reserved.delegated += deltaDelegatedReward;
    } else {
      reward.reserved.base -= deltaBaseReward;
      reward.reserved.delegated -= deltaDelegatedReward;
    }
  }

  /// @notice Increase reserved staker rewards.
  /// @param baseRewardAmount The amount of base rewards to reserve
  /// or unreserve for
  /// @param delegatedRewardAmount The amount of delegated rewards to reserve
  /// or unreserve for
  function _reserve(
    Reward storage reward,
    uint256 baseRewardAmount,
    uint256 delegatedRewardAmount
  ) internal {
    _updateReservedRewards(
      reward,
      baseRewardAmount,
      delegatedRewardAmount,
      true
    );
  }

  /// @notice Decrease reserved staker rewards.
  /// @param baseRewardAmount The amount of base rewards to reserve
  /// or unreserve for
  /// @param delegatedRewardAmount The amount of delegated rewards to reserve
  /// or unreserve for
  function _unreserve(
    Reward storage reward,
    uint256 baseRewardAmount,
    uint256 delegatedRewardAmount
  ) internal {
    _updateReservedRewards(
      reward,
      baseRewardAmount,
      delegatedRewardAmount,
      false
    );
  }

  /// @notice function does multiple things:
  /// - Unreserves future staking rewards to make them available for withdrawal;
  /// - Expires the reward to stop rewards from accumulating;
  function _release(
    Reward storage reward,
    uint256 amount,
    uint256 delegatedAmount
  ) internal {
    // Accumulate base and delegation rewards before unreserving rewards to save gas costs.
    // We can use the accumulated reward per micro LINK and accumulated delegation reward
    // to simplify reward calculations in migrate() and unstake() instead of recalculating.
    _accumulateDelegationRewards(reward, delegatedAmount);
    _accumulateBaseRewards(reward);
    _unreserve(reward, amount - delegatedAmount, delegatedAmount);

    reward.endTimestamp = block.timestamp;
  }

  /// @notice calculates an amount that community stakers have to delegate to operators
  /// @param amount base staked amount to calculate delegated amount against
  /// @param delegationRateDenominator Delegation rate used to calculate delegated stake amount
  function _getDelegatedAmount(
    uint256 amount,
    uint256 delegationRateDenominator
  ) internal pure returns (uint256) {
    return amount / delegationRateDenominator;
  }

  /// @notice calculates the amount of stake that remains after accounting for delegation requirement
  /// @param amount base staked amount to calculate non-delegated amount against
  /// @param delegationRateDenominator Delegation rate used to calculate delegated stake amount
  function _getNonDelegatedAmount(
    uint256 amount,
    uint256 delegationRateDenominator
  ) internal pure returns (uint256) {
    return amount - _getDelegatedAmount(amount, delegationRateDenominator);
  }

  /// @return uint256 the remaining reward duration (time until end), or 0 if expired/ended.
  function _getRemainingDuration(Reward storage reward)
    internal
    view
    returns (uint256)
  {
    return _isDepleted(reward) ? 0 : reward.endTimestamp - block.timestamp;
  }

  /// @notice This function is called when the staking pool is initialized,
  /// pool size is changed, reward rates are changed, rewards are added, and an alert is raised
  /// @param maxPoolSize Current maximum staking pool size
  /// @param totalStakedAmount Currently staked amount across community stakers and operators
  /// @param newRate New reward rate if it needs to be changed
  /// @param minRewardDuration The minimum duration rewards need to last for
  /// @param availableReward available reward amount
  /// @param totalDelegatedAmount total delegated amount delegated by community stakers
  function _updateDuration(
    Reward storage reward,
    uint256 maxPoolSize,
    uint256 totalStakedAmount,
    uint256 newRate,
    uint256 minRewardDuration,
    uint256 availableReward,
    uint256 totalDelegatedAmount
  ) internal {
    uint256 earnedBaseRewards = _getEarnedBaseRewards(
      reward,
      totalStakedAmount,
      totalDelegatedAmount
    );
    uint256 earnedDelegationRewards = _getEarnedDelegationRewards(
      reward,
      totalDelegatedAmount
    );

    uint256 remainingRewards = availableReward -
      earnedBaseRewards -
      earnedDelegationRewards;

    if (newRate != uint256(reward.base.rate)) {
      reward.base.rate = newRate._toUint80();
    }

    uint256 availableRewardDuration = (remainingRewards * REWARD_PRECISION) /
      (newRate * maxPoolSize);

    // Validate that the new reward duration is at least the min reward duration.
    // This is a safety mechanism to guard against operational mistakes.
    if (availableRewardDuration < minRewardDuration)
      revert RewardDurationTooShort();

    // Because we utilize unreserved rewards we need to update reserved amounts as well.
    // Reserved amounts are set to currently earned rewards plus new future rewards
    // based on the available reward duration.
    reward.reserved.base = (earnedBaseRewards +
      // Future base rewards for currently staked amounts based on the new duration
      _calculateReward(
        reward,
        totalStakedAmount - totalDelegatedAmount,
        availableRewardDuration
      ))._toUint96();

    reward.reserved.delegated = (earnedDelegationRewards +
      // Future delegation rewards for currently staked amounts based on the new duration
      _calculateReward(reward, totalDelegatedAmount, availableRewardDuration))
      ._toUint96();

    reward.endTimestamp = block.timestamp + availableRewardDuration;
  }

  /// @return The total amount of base rewards earned by all stakers
  function _getEarnedBaseRewards(
    Reward storage reward,
    uint256 totalStakedAmount,
    uint256 totalDelegatedAmount
  ) internal view returns (uint256) {
    return
      reward.reserved.base -
      _calculateReward(
        reward,
        totalStakedAmount - totalDelegatedAmount,
        _getRemainingDuration(reward)
      );
  }

  /// @return The total amount of delegated rewards earned by all node operators
  function _getEarnedDelegationRewards(
    Reward storage reward,
    uint256 totalDelegatedAmount
  ) internal view returns (uint256) {
    return
      reward.reserved.delegated -
      _calculateReward(
        reward,
        totalDelegatedAmount,
        _getRemainingDuration(reward)
      );
  }

  /// @notice Slashes all on feed node operators.
  /// Node operators are slashed the minimum of either the
  /// amount of rewards they have earned or the amount
  /// of rewards earned by the minimum operator stake amount
  /// over the slashable duration.
  function _slashOnFeedOperators(
    Reward storage reward,
    uint256 minOperatorStakeAmount,
    uint256 slashableDuration,
    address[] memory feedOperators,
    mapping(address => StakingPoolLib.Staker) storage stakers,
    uint256 totalDelegatedAmount
  ) internal {
    if (reward.delegated.delegatesCount == 0) return; // Skip slashing if there are no staking operators

    uint256 slashableBaseRewards = _getSlashableBaseRewards(
      reward,
      minOperatorStakeAmount,
      slashableDuration
    );
    uint256 slashableDelegatedRewards = _getSlashableDelegatedRewards(
      reward,
      slashableDuration,
      totalDelegatedAmount
    );

    uint256 totalSlashedBaseReward;
    uint256 totalSlashedDelegatedReward;

    uint256[] memory slashedBaseAmounts = new uint256[](feedOperators.length);
    uint256[] memory slashedDelegatedAmounts = new uint256[](
      feedOperators.length
    );

    for (uint256 i; i < feedOperators.length; i++) {
      address operator = feedOperators[i];
      uint256 operatorStakedAmount = stakers[operator].stakedAmount;
      if (operatorStakedAmount == 0) continue;
      slashedBaseAmounts[i] = _slashOperatorBaseRewards(
        reward,
        slashableBaseRewards,
        operator,
        operatorStakedAmount
      );
      slashedDelegatedAmounts[i] = _slashOperatorDelegatedRewards(
        reward,
        slashableDelegatedRewards,
        operator,
        totalDelegatedAmount
      );
      totalSlashedBaseReward += slashedBaseAmounts[i];
      totalSlashedDelegatedReward += slashedDelegatedAmounts[i];
    }
    reward.reserved.base -= totalSlashedBaseReward._toUint96();
    reward.reserved.delegated -= totalSlashedDelegatedReward._toUint96();

    emit RewardSlashed(
      feedOperators,
      slashedBaseAmounts,
      slashedDelegatedAmounts
    );
  }

  /// @return The amount of base rewards to slash
  /// @notice The amount of rewards accrued over the slashable duration for a
  /// minimum node operator stake amount
  function _getSlashableBaseRewards(
    Reward storage reward,
    uint256 minOperatorStakeAmount,
    uint256 slashableDuration
  ) private view returns (uint256) {
    return _calculateReward(reward, minOperatorStakeAmount, slashableDuration);
  }

  /// @return The amount of delegated rewards to slash
  /// @dev The amount of delegated rewards accrued over the slashable duration
  function _getSlashableDelegatedRewards(
    Reward storage reward,
    uint256 slashableDuration,
    uint256 totalDelegatedAmount
  ) private view returns (uint256) {
    DelegatedRewards memory delegatedRewards = reward.delegated;

    return
      _calculateReward(reward, totalDelegatedAmount, slashableDuration) /
      // We don't validate for delegatedRewards.delegatesCount to be a
      // non-zero value as this is already checked in _slashOnFeedOperators.
      uint256(delegatedRewards.delegatesCount);
  }

  /// @notice Slashes an on feed node operator the minimum of
  /// either the total amount of base rewards they have
  /// earned or the amount of rewards earned by the
  ///  minimum operator stake amount over the slashable duration.
  function _slashOperatorBaseRewards(
    Reward storage reward,
    uint256 slashableRewards,
    address operator,
    uint256 operatorStakedAmount
  ) private returns (uint256) {
    uint256 earnedRewards = _getOperatorEarnedBaseRewards(
      reward,
      operator,
      operatorStakedAmount
    );
    uint256 slashedRewards = Math.min(slashableRewards, earnedRewards); // max capped by earnings
    reward.missed[operator].base += slashedRewards._toUint96();
    return slashedRewards;
  }

  /// @notice Slashes an on feed node operator the minimum of
  /// either the total amount of delegated rewards they have
  /// earned or the amount of delegated rewards they have
  /// earned over the slashable duration.
  function _slashOperatorDelegatedRewards(
    Reward storage reward,
    uint256 slashableRewards,
    address operator,
    uint256 totalDelegatedAmount
  ) private returns (uint256) {
    uint256 earnedRewards = _getOperatorEarnedDelegatedRewards(
      reward,
      operator,
      totalDelegatedAmount
    );
    uint256 slashedRewards = Math.min(slashableRewards, earnedRewards); // max capped by earnings
    reward.missed[operator].delegated += slashedRewards._toUint96();
    return slashedRewards;
  }

  /// @return The amount of base rewards an operator
  /// has earned.
  function _getOperatorEarnedBaseRewards(
    Reward storage reward,
    address operator,
    uint256 operatorStakedAmount
  ) internal view returns (uint256) {
    return
      _calculateAccruedBaseRewards(reward, operatorStakedAmount) -
      uint256(reward.missed[operator].base);
  }

  /// @return The amount of delegated rewards an operator
  /// has earned.
  function _getOperatorEarnedDelegatedRewards(
    Reward storage reward,
    address operator,
    uint256 totalDelegatedAmount
  ) internal view returns (uint256) {
    return
      _calculateAccruedDelegatedRewards(reward, totalDelegatedAmount) -
      uint256(reward.missed[operator].delegated);
  }

  /// @return The current timestamp or, if the current timestamp has passed reward
  /// end timestamp, reward end timestamp.
  /// @dev This is necessary to ensure that rewards are calculated correctly
  /// after the reward is depleted.
  function _getCappedTimestamp(Reward storage reward)
    internal
    view
    returns (uint256)
  {
    return Math.min(uint256(reward.endTimestamp), block.timestamp);
  }
}