// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

/// @notice Library to assist with calculation methods of the balances, ends, period amounts for a given plan
/// used by both the Lockup and Vesting Plans
library TimelockLibrary {
  function min(uint256 a, uint256 b) internal pure returns (uint256 _min) {
    _min = (a <= b) ? a : b;
  }

  /// @notice function to calculate the end date of a plan based on its start, amount, rate and period
  function endDate(uint256 start, uint256 amount, uint256 rate, uint256 period) internal pure returns (uint256 end) {
    end = (amount % rate == 0) ? (amount / rate) * period + start : ((amount / rate) * period) + period + start;
  }

  /// @notice function to calculate the end period and validate that the parameters passed in are valid
  function validateEnd(
    uint256 start,
    uint256 cliff,
    uint256 amount,
    uint256 rate,
    uint256 period
  ) internal pure returns (uint256 end, bool valid) {
    require(amount > 0, '0_amount');
    require(rate > 0, '0_rate');
    require(rate <= amount, 'rate > amount');
    require(period > 0, '0_period');
    end = (amount % rate == 0) ? (amount / rate) * period + start : ((amount / rate) * period) + period + start;
    require(cliff <= end, 'cliff > end');
    valid = true;
  }

  /// @notice function to calculate the unlocked (claimable) balance, still locked balance, and the most recent timestamp the unlock would take place
  /// the most recent unlock time is based on the periods, so if the periods are 1, then the unlock time will be the same as the redemption time,
  /// however if the period more than 1 second, the latest unlock will be a discrete time stamp
  /// @param start is the start time of the plan
  /// @param cliffDate is the timestamp of the cliff of the plan
  /// @param amount is the total unclaimed amount tokens still in the vesting plan
  /// @param rate is the amount of tokens that unlock per period
  /// @param period is the seconds in each period, a 1 is a period of 1 second whereby tokens unlock every second
  /// @param currentTime is the current time being evaluated, typically the block.timestamp, but used just to check the plan is past the start or cliff
  /// @param redemptionTime is the time requested for the plan to be redeemed, this can be the same as the current time or prior to it for partial redemptions
  function balanceAtTime(
    uint256 start,
    uint256 cliffDate,
    uint256 amount,
    uint256 rate,
    uint256 period,
    uint256 currentTime,
    uint256 redemptionTime
  ) internal pure returns (uint256 unlockedBalance, uint256 lockedBalance, uint256 unlockTime) {
    if (start > currentTime || cliffDate > currentTime || redemptionTime <= start) {
      lockedBalance = amount;
      unlockTime = start;
    } else {
      uint256 periodsElapsed = (redemptionTime - start) / period;
      uint256 calculatedBalance = periodsElapsed * rate;
      unlockedBalance = min(calculatedBalance, amount);
      lockedBalance = amount - unlockedBalance;
      unlockTime = start + (period * periodsElapsed);
    }
  }

  function calculateCombinedRate(
    uint256 combinedAmount,
    uint256 combinedRates,
    uint256 start,
    uint256 period,
    uint256 targetEnd
  ) internal pure returns (uint256 rate, uint256 end) {
    uint256 numerator = combinedAmount * period;
    uint256 denominator = (combinedAmount % combinedRates == 0) ? targetEnd - start : targetEnd - start - period;
    rate = numerator / denominator;
    end = endDate(start, combinedAmount, rate, period);
  }

  function calculateSegmentRates(
    uint256 originalRate,
    uint256 originalAmount,
    uint256 planAmount,
    uint256 segmentAmount,
    uint256 start,
    uint256 end,
    uint256 period,
    uint256 cliff
  ) internal pure returns (uint256 planRate, uint256 segmentRate, uint256 planEnd, uint256 segmentEnd) {
    planRate = (originalRate * ((planAmount * (10 ** 18)) / originalAmount)) / (10 ** 18);
    segmentRate = (segmentAmount % (originalRate - planRate) == 0)
      ? (segmentAmount * period) / (end - start)
      : (segmentAmount * period) / (end - start - period);
    bool validPlanEnd;
    bool validSegmentEnd;
    (planEnd, validPlanEnd) = validateEnd(start, cliff, planAmount, planRate, period);
    (segmentEnd, validSegmentEnd) = validateEnd(start, cliff, segmentAmount, segmentRate, period);
    require(validPlanEnd && validSegmentEnd, 'invalid end date');
  }
}