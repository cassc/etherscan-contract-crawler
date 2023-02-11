// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { SafeCast } from "../lib/SafeCast.sol";
import { LS1EpochSchedule } from "./LS1EpochSchedule.sol";
import { LS1Types } from '../lib/LS1Types.sol';

/**
 * @title LS1Rewards
 * @author MarginX
 *
 * @dev Manages the distribution of token rewards.
 *
 *  Rewards are distributed continuously. After each second, an account earns rewards `r` according
 *  to the following formula:
 *
 *      r = R * s / S
 *
 *  Where:
 *    - `R` is the rewards distributed globally each second, also called the “emission rate.”
 *    - `s` is the account's staked balance in that second (technically, it is measured at the
 *      end of the second)
 *    - `S` is the sum total of all staked balances in that second (again, measured at the end of
 *      the second)
 *
 *  The parameter `R` can be configured by the contract owner. For every second that elapses,
 *  exactly `R` tokens will accrue to users, save for rounding errors, and with the exception that
 *  while the total staked balance is zero, no tokens will accrue to anyone.
 *
 *  The accounting works as follows: A global index is stored which represents the cumulative
 *  number of rewards tokens earned per staked token since the start of the distribution.
 *  The value of this index increases over time, and there are two factors affecting the rate of
 *  increase:
 *    1) The emission rate (in the numerator)
 *    2) The total number of staked tokens (in the denominator)
 *
 *  Whenever either factor changes, in some timestamp T, we settle the global index up to T by
 *  calculating the increase in the index since the last update using the OLD values of the factors:
 *
 *    indexDelta = timeDelta * emissionPerSecond * INDEX_BASE / totalStaked
 *
 *  Where `INDEX_BASE` is a scaling factor used to allow more precision in the storage of the index.
 *
 *  For each user we store an accrued rewards balance, as well as a user index, which is a cache of
 *  the global index at the time that the user's accrued rewards balance was last updated. Then at
 *  any point in time, a user's claimable rewards are represented by the following:
 *
 *    rewards = _USER_REWARDS_BALANCES_[user] + userStaked * (
 *                settledGlobalIndex - _USER_INDEXES_[user]
 *              ) / INDEX_BASE
 */
abstract contract LS1Rewards is
  LS1EpochSchedule
{
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeCast for uint256;
  using SafeMathUpgradeable for uint256;

  // ============ Constants ============

  /// @dev Additional precision used to represent the global and user index values.
  uint256 private constant INDEX_BASE = 10**18;

  /// @notice The rewards token.
  IERC20Upgradeable public REWARDS_TOKEN;

  /// @notice Address to pull rewards from. Must have provided an allowance to this contract.
  address public REWARDS_TREASURY;

  /// @notice Start timestamp (inclusive) of the period in which rewards can be earned.
  uint256 public DISTRIBUTION_START;

  /// @notice End timestamp (exclusive) of the period in which rewards can be earned.
  uint256 public DISTRIBUTION_END;

  // ============ Events ============

  event RewardsPerSecondUpdated(
    uint256 emissionPerSecond
  );

  event GlobalIndexUpdated(
    uint256 index
  );

  event UserIndexUpdated(
    address indexed user,
    uint256 index,
    uint256 unclaimedRewards
  );

  event ClaimedRewards(
    address indexed user,
    address recipient,
    uint256 claimedRewards
  );

  // ============ External Functions ============

  /**
   * @notice The current emission rate of rewards.
   *
   * @return The number of rewards tokens issued globally each second.
   */
  function getRewardsPerSecond()
    external
    view
    returns (uint256)
  {
    return _REWARDS_PER_SECOND_;
  }


  function getStakerReward(address staker)
    external
    view
    returns (uint256)
  {
    uint256 _global_index_timestamp_ =_GLOBAL_INDEX_TIMESTAMP_;
    uint256 _global_index_ = _GLOBAL_INDEX_;
    uint256 _user_rewards_balances_ = _USER_REWARDS_BALANCES_[staker];
    uint256 _user_index_ = _USER_INDEXES_[staker];
    uint256 _epoch_indexes_beforeRolloverEpoch_;

    // 1) Always settle total active balance before settling a staker active balance. -> uint256 totalBalance = _settleBalance(address(0), true);
    LS1Types.StoredBalance memory balancePtr = _TOTAL_ACTIVE_BALANCE_;
    LS1Types.StoredBalance memory balance = _TOTAL_ACTIVE_BALANCE_;

    // Return these as they may be needed for rewards settlement.
    bool didRolloverOccur = false;

    // Roll the balance forward if needed.
    if (getCurrentEpoch() > uint256(balance.currentEpoch)) {
      didRolloverOccur = balance.currentEpochBalance != balance.nextEpochBalance;

      balance.currentEpoch = uint16(getCurrentEpoch());
      balance.currentEpochBalance = balance.nextEpochBalance;
    }

    if (didRolloverOccur) {
      uint256 settleUpToTimestamp = getStartOfEpoch(uint256(balancePtr.currentEpoch).add(1));
      uint256 intervalStart = _global_index_timestamp_;
      // uint256 intervalEnd = MathUpgradeable.min(settleUpToTimestamp, DISTRIBUTION_END);

      if (MathUpgradeable.min(settleUpToTimestamp, DISTRIBUTION_END) <= intervalStart) {
        // globalIndex = oldGlobalIndex;
      } else {
        // Note: If we reach this point, we must update _global_index_timestamp_.
        uint256 emissionPerSecond = _REWARDS_PER_SECOND_;

        if (emissionPerSecond == 0 || uint256(balancePtr.currentEpochBalance) == 0) {
          _global_index_timestamp_ = uint32(MathUpgradeable.min(settleUpToTimestamp, DISTRIBUTION_END));
        } else {
          // Calculate the change in index over the interval and Update storage.(Shared storage slot.)
          _global_index_timestamp_ = uint32(MathUpgradeable.min(settleUpToTimestamp, DISTRIBUTION_END));
          _global_index_ = _global_index_.add(MathUpgradeable.min(settleUpToTimestamp, DISTRIBUTION_END).sub(intervalStart).mul(emissionPerSecond).mul(10**18).div(balancePtr.currentEpochBalance));
        }
      }
      _epoch_indexes_beforeRolloverEpoch_ = _global_index_;
    }
    uint256 totalBalance = uint256(balance.currentEpochBalance);

    // 2) Always settle staker active balance before settling staker rewards. -> uint256 userBalance = _settleBalance(staker, true);
    LS1Types.StoredBalance memory balancePtr2 = _ACTIVE_BALANCES_[staker];
    balance = _ACTIVE_BALANCES_[staker];

    // Return these as they may be needed for rewards settlement.
    didRolloverOccur = false;

    // Roll the balance forward if needed.
    if (getCurrentEpoch() > uint256(balance.currentEpoch)) {
      didRolloverOccur = balance.currentEpochBalance != balance.nextEpochBalance;

      balance.currentEpoch = uint16(getCurrentEpoch());
      balance.currentEpochBalance = balance.nextEpochBalance;
    }

    if (didRolloverOccur) {
      uint256 globalIndexBeforeRolloverEpoch;
      if(balancePtr2.currentEpoch == balancePtr.currentEpoch) {
        globalIndexBeforeRolloverEpoch = _epoch_indexes_beforeRolloverEpoch_;
      } else {
        globalIndexBeforeRolloverEpoch = _EPOCH_INDEXES_[balancePtr2.currentEpoch];
      }

      if (_user_index_ != globalIndexBeforeRolloverEpoch) {
        // make sure globalIndexBeforeRolloverEpoch cannot equal to 0 to prevent error
        if (balancePtr2.currentEpochBalance != 0 && globalIndexBeforeRolloverEpoch!= 0) {
          // Calculate newly accrued rewards since the last update to the user's index.
          _user_rewards_balances_ = _user_rewards_balances_.add(uint256(balancePtr2.currentEpochBalance).mul(globalIndexBeforeRolloverEpoch.sub(_user_index_)).div(10**18));
        }
        // Update the user's index.
        _user_index_ = globalIndexBeforeRolloverEpoch;
      }
    }
    uint256 userBalance =  uint256(balance.currentEpochBalance);

    // 3) Settle rewards balance since we want to claim the full accrued amount. -> _settleUserRewardsUpToNow(staker, userBalance, totalBalance);
    if (MathUpgradeable.min(block.timestamp, DISTRIBUTION_END) > _global_index_timestamp_) {
      if (_REWARDS_PER_SECOND_ != 0 && totalBalance != 0) {
        // Calculate the change in index over the interval. 
        uint256 timeDelta = MathUpgradeable.min(block.timestamp, DISTRIBUTION_END).sub(_global_index_timestamp_);

        // Calculate, update, and return the new global index.
        _global_index_ = _global_index_.add(timeDelta.mul(_REWARDS_PER_SECOND_).mul(10**18).div(totalBalance));
      }
    }

    uint256 accruedRewardsDelta;
    if (_user_index_ != _global_index_) {
      if (userBalance != 0) {
        // Calculate newly accrued rewards since the last update to the user's index.
        accruedRewardsDelta = userBalance.mul(_global_index_.sub(_user_index_)).div(10**18);
      }
    }
    
    return _user_rewards_balances_.add(accruedRewardsDelta);
  }

  // ============ Internal Functions ============

  /**
   * @dev Initialize the contract.
   */
  function __LS1Rewards_init()
    internal
  {
    _GLOBAL_INDEX_TIMESTAMP_ = MathUpgradeable.max(block.timestamp, DISTRIBUTION_START).toUint32();
  }

  /**
   * @dev Set the emission rate of rewards.
   *
   *  IMPORTANT: Do not call this function without settling the total staked balance first, to
   *  ensure that the index is settled up to the epoch boundaries.
   *
   * @param  emissionPerSecond  The new number of rewards tokens to give out each second.
   * @param  totalStaked        The total staked balance.
   */
  function _setRewardsPerSecond(
    uint256 emissionPerSecond,
    uint256 totalStaked
  )
    internal
  {
    _settleGlobalIndexUpToNow(totalStaked);
    _REWARDS_PER_SECOND_ = emissionPerSecond;
    emit RewardsPerSecondUpdated(emissionPerSecond);
  }

  /**
   * @dev Claim tokens, sending them to the specified recipient.
   *
   *  Note: In order to claim all accrued rewards, the total and user staked balances must first be
   *  settled before calling this function.
   *
   * @param  user       The user's address.
   * @param  recipient  The address to send rewards to.
   *
   * @return The number of rewards tokens claimed.
   */
  function _claimRewards(
    address user,
    address recipient
  )
    internal
    returns (uint256)
  {
    uint256 accruedRewards = _USER_REWARDS_BALANCES_[user];
    _USER_REWARDS_BALANCES_[user] = 0;
    REWARDS_TOKEN.safeTransferFrom(REWARDS_TREASURY, recipient, accruedRewards);
    emit ClaimedRewards(user, recipient, accruedRewards);
    return accruedRewards;
  }

  /**
   * @dev Settle a user's rewards up to the latest global index as of `block.timestamp`. Triggers a
   *  settlement of the global index up to `block.timestamp`. Should be called with the OLD user
   *  and total balances.
   *
   * @param  user         The user's address.
   * @param  userStaked   Tokens staked by the user during the period since the last user index
   *                      update.
   * @param  totalStaked  Total tokens staked by all users during the period since the last global
   *                      index update.
   *
   * @return The user's accrued rewards, including past unclaimed rewards.
   */
  function _settleUserRewardsUpToNow(
    address user,
    uint256 userStaked,
    uint256 totalStaked
  )
    internal
    returns (uint256)
  {
    uint256 globalIndex = _settleGlobalIndexUpToNow(totalStaked);
    return _settleUserRewardsUpToIndex(user, userStaked, globalIndex);
  }

  /**
   * @dev Settle a user's rewards up to an epoch boundary. Should be used to partially settle a
   *  user's rewards if their balance was known to have changed on that epoch boundary.
   *
   * @param  user         The user's address.
   * @param  userStaked   Tokens staked by the user. Should be accurate for the time period
   *                      since the last update to this user and up to the end of the
   *                      specified epoch.
   * @param  epochNumber  Settle the user's rewards up to the end of this epoch.
   *
   * @return The user's accrued rewards, including past unclaimed rewards, up to the end of the
   *  specified epoch.
   */
  function _settleUserRewardsUpToEpoch(
    address user,
    uint256 userStaked,
    uint256 epochNumber
  )
    internal
    returns (uint256)
  {
    uint256 globalIndex = _EPOCH_INDEXES_[epochNumber];
    return _settleUserRewardsUpToIndex(user, userStaked, globalIndex);
  }

  /**
   * @dev Settle the global index up to the end of the given epoch.
   *
   *  IMPORTANT: This function should only be called under conditions which ensure the following:
   *    - `epochNumber` < the current epoch number
   *    - `_GLOBAL_INDEX_TIMESTAMP_ < settleUpToTimestamp`
   *    - `_EPOCH_INDEXES_[epochNumber] = 0`
   */
  function _settleGlobalIndexUpToEpoch(
    uint256 totalStaked,
    uint256 epochNumber
  )
    internal
    returns (uint256)
  {
    uint256 settleUpToTimestamp = getStartOfEpoch(epochNumber.add(1));

    uint256 globalIndex = _settleGlobalIndexUpToTimestamp(totalStaked, settleUpToTimestamp);
    _EPOCH_INDEXES_[epochNumber] = globalIndex;
    return globalIndex;
  }

  // ============ Private Functions ============

  function _settleGlobalIndexUpToNow(
    uint256 totalStaked
  )
    private
    returns (uint256)
  {
    return _settleGlobalIndexUpToTimestamp(totalStaked, block.timestamp);
  }

  /**
   * @dev Helper function which settles a user's rewards up to a global index. Should be called
   *  any time a user's staked balance changes, with the OLD user and total balances.
   *
   * @param  user            The user's address.
   * @param  userStaked      Tokens staked by the user during the period since the last user index
   *                         update.
   * @param  newGlobalIndex  The new index value to bring the user index up to.
   *
   * @return The user's accrued rewards, including past unclaimed rewards.
   */
  function _settleUserRewardsUpToIndex(
    address user,
    uint256 userStaked,
    uint256 newGlobalIndex
  )
    private
    returns (uint256)
  {
    uint256 oldAccruedRewards = _USER_REWARDS_BALANCES_[user];
    uint256 oldUserIndex = _USER_INDEXES_[user];

    if (oldUserIndex == newGlobalIndex) {
      return oldAccruedRewards;
    }

    uint256 newAccruedRewards;
    if (userStaked == 0) {
      // Note: Even if the user's staked balance is zero, we still need to update the user index.
      newAccruedRewards = oldAccruedRewards;
    } else {
      // Calculate newly accrued rewards since the last update to the user's index.
      uint256 indexDelta = newGlobalIndex.sub(oldUserIndex);
      uint256 accruedRewardsDelta = userStaked.mul(indexDelta).div(INDEX_BASE);
      newAccruedRewards = oldAccruedRewards.add(accruedRewardsDelta);

      // Update the user's rewards.
      _USER_REWARDS_BALANCES_[user] = newAccruedRewards;
    }

    // Update the user's index.
    _USER_INDEXES_[user] = newGlobalIndex;
    emit UserIndexUpdated(user, newGlobalIndex, newAccruedRewards);
    return newAccruedRewards;
  }

  /**
   * @dev Updates the global index, reflecting cumulative rewards given out per staked token.
   *
   * @param  totalStaked          The total staked balance, which should be constant in the interval
   *                              (_GLOBAL_INDEX_TIMESTAMP_, settleUpToTimestamp).
   * @param  settleUpToTimestamp  The timestamp up to which to settle rewards. It MUST satisfy
   *                              `settleUpToTimestamp <= block.timestamp`.
   *
   * @return The new global index.
   */
  function _settleGlobalIndexUpToTimestamp(
    uint256 totalStaked,
    uint256 settleUpToTimestamp
  )
    private
    returns (uint256)
  {
    uint256 oldGlobalIndex = uint256(_GLOBAL_INDEX_);

    // The goal of this function is to calculate rewards earned since the last global index update.
    // These rewards are earned over the time interval which is the intersection of the intervals
    // [_GLOBAL_INDEX_TIMESTAMP_, settleUpToTimestamp] and [DISTRIBUTION_START, DISTRIBUTION_END].
    //
    // We can simplify a bit based on the assumption:
    //   `_GLOBAL_INDEX_TIMESTAMP_ >= DISTRIBUTION_START`
    //
    // Get the start and end of the time interval under consideration.
    uint256 intervalStart = uint256(_GLOBAL_INDEX_TIMESTAMP_);
    uint256 intervalEnd = MathUpgradeable.min(settleUpToTimestamp, DISTRIBUTION_END);

    // Return early if the interval has length zero (incl. case where intervalEnd < intervalStart).
    if (intervalEnd <= intervalStart) {
      return oldGlobalIndex;
    }

    // Note: If we reach this point, we must update _GLOBAL_INDEX_TIMESTAMP_.

    uint256 emissionPerSecond = _REWARDS_PER_SECOND_;

    if (emissionPerSecond == 0 || totalStaked == 0) {
      // Ensure a log is emitted if the timestamp changed, even if the index does not change.
      _GLOBAL_INDEX_TIMESTAMP_ = intervalEnd.toUint32();
      emit GlobalIndexUpdated(oldGlobalIndex);
      return oldGlobalIndex;
    }

    // Calculate the change in index over the interval.
    uint256 timeDelta = intervalEnd.sub(intervalStart);
    uint256 indexDelta = timeDelta.mul(emissionPerSecond).mul(INDEX_BASE).div(totalStaked);

    // Calculate, update, and return the new global index.
    uint256 newGlobalIndex = oldGlobalIndex.add(indexDelta);

    // Update storage. (Shared storage slot.)
    _GLOBAL_INDEX_TIMESTAMP_ = intervalEnd.toUint32();
    _GLOBAL_INDEX_ = newGlobalIndex.toUint128();

    emit GlobalIndexUpdated(newGlobalIndex);
    return newGlobalIndex;
  }
}