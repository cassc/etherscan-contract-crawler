// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../external-lib/SafeDecimalMath.sol";

import "../interfaces/multiplier/IMultiStake.sol";
import "../interfaces/multiplier/IBonusScaling.sol";

contract MultiplierMath is IBonusScaling, IMultiStake {
  using SafeMath for uint256;
  using SafeDecimalMath for uint256;

  struct UnstakeOutput {
    // [e18] amount left staked in last stake array
    uint256 lastStakeAmount;
    // [e18] number of stakes left
    uint256 newStakesCount;
    // [e18] stake seconds
    uint256 rawStakeSeconds;
    // [e18] bonus weighted stake seconds
    uint256 bonusWeightedStakeSeconds;
    // [e18] reward tokens due
    uint256 rewardDue;
    // [e18] total stake seconds adjusting for new unstaking
    uint256 newTotalStakeSeconds;
  }

  /**
   * @notice Calculate accrued stake seconds given a period
   * @param amount [eD] token amount
   * @param start [seconds] epoch timestamp
   * @param end [seconds] epoch timestamp up to
   * @return stakeSeconds accrued stake seconds
   */
  function calculateStakeSeconds(
    uint256 amount,
    uint256 start,
    uint256 end
  ) internal pure returns (uint256 stakeSeconds) {
    uint256 duration = end.sub(start);
    stakeSeconds = duration.mul(amount);
    return stakeSeconds;
  }

  /**
   * @dev Calculate the time bonus
   * @param bs BonusScaling used to calculate time bonus
   * @param duration length of time staked for
   * @return bonus [e18] fixed point fraction, UNIT = +100%
   */
  function timeBonus(BonusScaling memory bs, uint256 duration)
    internal
    pure
    returns (uint256 bonus)
  {
    if (duration >= bs.period) {
      return bs.max;
    }

    uint256 bonusScale = bs.max.sub(bs.min);
    uint256 bonusAddition = bonusScale.mul(duration).div(bs.period);
    bonus = bs.min.add(bonusAddition);
  }

  /**
   * @dev Calculate total stake seconds
   */
  function calculateTotalStakeSeconds(
    uint256 cachedTotalStakeAmount,
    uint256 cachedTotalStakeSeconds,
    uint256 lastUpdateTimestamp,
    uint256 timestamp
  ) internal pure returns (uint256 totalStakeSeconds) {
    if (timestamp == lastUpdateTimestamp) return cachedTotalStakeSeconds;

    uint256 additionalStakeSeconds =
      calculateStakeSeconds(
        cachedTotalStakeAmount,
        lastUpdateTimestamp,
        timestamp
      );

    totalStakeSeconds = cachedTotalStakeSeconds.add(additionalStakeSeconds);
  }

  /**
   * @dev Calculates reward from a given set of stakes
   * - Should check for total stake before calling
   * @param stakes Set of stakes
   */
  function simulateUnstake(
    Stake[] memory stakes,
    uint256 amountToUnstake,
    uint256 totalStakeSeconds,
    uint256 unlockedRewardAmount,
    uint256 timestamp,
    BonusScaling memory bs
  ) internal pure returns (UnstakeOutput memory out) {
    uint256 stakesToDrop = 0;
    while (amountToUnstake > 0) {
      uint256 targetIndex = stakes.length.sub(stakesToDrop).sub(1);
      Stake memory lastStake = stakes[targetIndex];

      uint256 currentAmount;
      if (lastStake.amount > amountToUnstake) {
        // set current amount to remaining unstake amount
        currentAmount = amountToUnstake;
        // amount of last stake is reduced
        out.lastStakeAmount = lastStake.amount.sub(amountToUnstake);
      } else {
        // set current amount to amount of last stake
        currentAmount = lastStake.amount;
        // add to stakes to drop
        stakesToDrop += 1;
      }

      amountToUnstake = amountToUnstake.sub(currentAmount);

      // Calculate staked seconds from amount
      uint256 stakeSeconds =
        calculateStakeSeconds(currentAmount, lastStake.timestamp, timestamp);

      // [e18] fixed point time bonus, 100% + X%
      uint256 bonus =
        SafeDecimalMath.UNIT.add(
          timeBonus(bs, timestamp.sub(lastStake.timestamp))
        );

      out.rawStakeSeconds = out.rawStakeSeconds.add(stakeSeconds);
      out.bonusWeightedStakeSeconds = out.bonusWeightedStakeSeconds.add(
        stakeSeconds.multiplyDecimal(bonus)
      );
    }

    // Update virtual caches
    out.newTotalStakeSeconds = totalStakeSeconds.sub(out.rawStakeSeconds);

    //              M_time * h
    // R = K *  ------------------
    //          H - h + M_time * h
    //
    // R - rewards due
    // K - total unlocked rewards
    // M_time - bonus related to time
    // h - user stake seconds
    // H - total stake seconds
    // H-h - new total stake seconds
    // R = 0 if H = 0
    if (totalStakeSeconds != 0) {
      out.rewardDue = unlockedRewardAmount
        .mul(out.bonusWeightedStakeSeconds)
        .div(out.newTotalStakeSeconds.add(out.bonusWeightedStakeSeconds));
    }

    return
      UnstakeOutput(
        out.lastStakeAmount,
        stakes.length.sub(stakesToDrop),
        out.rawStakeSeconds,
        out.bonusWeightedStakeSeconds,
        out.rewardDue,
        out.newTotalStakeSeconds
      );
  }
}