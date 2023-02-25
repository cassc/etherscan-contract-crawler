// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {Epochs} from "./Epochs.sol";

/// @dev Epoch Awareness
/// The Membership system relies on an epoch structure to incentivize economic behavior. Deposits
/// are tracked by epoch and only count toward yield enhancements if they have been present for
/// an entire epoch. This means positions have a specific lifetime:
/// 1. Deposit Epoch - Positions are in the membership system but do not count for rewards as they
///      were not in since the beginning of the epoch. Deposits are externally triggered.
/// 2. Eligible Epoch - Positions are in the membership system and count for rewards as they have been
///      present the entire epoch.
/// 3. Withdrawal Epoch - Positions are no longer in the membership system and forfeit their rewards
///      for the withdrawal epoch. Rewards are forfeited as the position was not present for the
///      entire epoch when withdrawn. Withdrawals are externally triggered.
///
/// All of these deposits' value is summed together to calculate the yield enhancement. A naive
/// approach is, for every summation query, iterate over all deposits and check if they were deposited
/// in the current epoch (so case (1)) or in a previous epoch (so case (2)). This has a high gas
/// cost, so we use another approach: UserEpochTotal.
///
/// UserEpochTotal is the total of the user's deposits as of its lastEpochUpdate- the last epoch that
/// the total was updated in. For that epoch, it tracks:
/// 1. Eligible Amount - The sum of deposits that are in their Eligible Epoch for the current epoch
/// 2. Total Amount - The sum of deposits that will be in their Eligible Epoch for the next epoch
///
/// It is not necessary to track previous epochs as deposits in those will already be eligible, or they
/// will have been withdrawn and already affected the eligible amount.
///
/// It is also unnecessary to track future epochs beyond the next one. Any deposit in the current epoch
/// will become eligible in the next epoch. It is not possible to have a deposit (or withdrawal) take
/// effect any further in the future.

struct UserEpochTotal {
  /// Total amount that will be eligible for membership, after `checkpointedAt` epoch
  uint256 totalAmount;
  /// Amount eligible for membership, as of `checkpointedAt` epoch
  uint256 eligibleAmount;
  /// Last epoch the total was checkpointed at
  uint256 checkpointedAt;
}

library UserEpochTotals {
  error InvalidDepositEpoch(uint256 epoch);

  /// @notice Record an increase of `amount` in the `total`. This is counted toward the
  ///  nextAmount as deposits must be present for an entire epoch to be valid.
  /// @param total storage pointer to the UserEpochTotal
  /// @param amount amount to increase the total by
  function recordIncrease(UserEpochTotal storage total, uint256 amount) internal {
    _checkpoint(total);

    total.totalAmount += amount;
  }

  /// @notice Record an increase of `amount` instantly based on the time of the deposit.
  ///  This is counted either:
  ///  1. To just the totalAmount if the deposit was this epoch
  ///  2. To both the totalAmount and eligibleAmount if the deposit was before this epoch
  /// @param total storage pointer to the UserEpochTotal
  /// @param amount amount to increase the total by
  function recordInstantIncrease(
    UserEpochTotal storage total,
    uint256 amount,
    uint256 depositTimestamp
  ) internal {
    uint256 depositEpoch = Epochs.fromSeconds(depositTimestamp);
    if (depositEpoch > Epochs.current()) revert InvalidDepositEpoch(depositEpoch);

    _checkpoint(total);

    if (depositEpoch < Epochs.current()) {
      // If this was deposited earlier, then it also counts towards eligible
      total.eligibleAmount += amount;
    }

    total.totalAmount += amount;
  }

  /// @notice Record a decrease of `amount` in the `total`. Depending on the `depositTimestamp`
  ///  this will withdraw from the total's currentAmount (if it's withdrawn from an already valid deposit)
  ///  or from the total's nextAmount (if it's withdrawn from a deposit this epoch).
  /// @param total storage pointer to the UserEpochTotal
  /// @param amount amount to decrease the total by
  /// @param depositTimestamp timestamp of the deposit associated with `amount`
  function recordDecrease(
    UserEpochTotal storage total,
    uint256 amount,
    uint256 depositTimestamp
  ) internal {
    uint256 depositEpoch = Epochs.fromSeconds(depositTimestamp);
    if (depositEpoch > Epochs.current()) revert InvalidDepositEpoch(depositEpoch);

    _checkpoint(total);

    total.totalAmount -= amount;

    if (depositEpoch < Epochs.current()) {
      // If this was deposited earlier, then it would have been promoted in _checkpoint and must be removed.
      total.eligibleAmount -= amount;
    }
  }

  /// @notice Get the up-to-date current and next amount for the `_total`. UserEpochTotals
  ///  may have a lastEpochUpdate of long ago. This returns the current and next amounts as if it had
  ///  been checkpointed just now.
  /// @param _total storage pointer to the UserEpochTotal
  /// @return current the currentAmount of the UserEpochTotal
  /// @return next the nextAmount of the UserEpochTotal
  function getTotals(
    UserEpochTotal storage _total
  ) internal view returns (uint256 current, uint256 next) {
    UserEpochTotal memory total = _total;
    if (Epochs.current() == total.checkpointedAt) {
      return (total.eligibleAmount, total.totalAmount);
    }

    return (total.totalAmount, total.totalAmount);
  }

  //////////////////////////////////////////////////////////////////
  // Private

  function _checkpoint(UserEpochTotal storage total) private {
    // Only promote the total amount if we've moved to the next epoch
    // after the last checkpoint.
    if (Epochs.current() <= total.checkpointedAt) return;

    total.eligibleAmount = total.totalAmount;

    total.checkpointedAt = Epochs.current();
  }
}