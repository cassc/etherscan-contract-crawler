// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/math/Math.sol";

import "../lib/BasisMath.sol";
import "../external-lib/SafeDecimalMath.sol";

contract AuctionHouseMath {
  using SafeMath for uint256;
  using SafeDecimalMath for uint256;
  using BasisMath for uint256;

  /**
   * @notice Calculate the maximum allowance for this action to do a price correction
   * This is normally an over-estimate as it assumes all Float is circulating
   * and the market cap is constant through supply changes.
   */
  function allowance(
    bool expansion,
    uint256 capBasisPoint,
    uint256 floatSupply,
    uint256 marketFloatPrice,
    uint256 targetFloatPrice
  ) internal pure returns (uint256) {
    uint256 targetSupply =
      marketFloatPrice.mul(floatSupply).div(targetFloatPrice);
    uint256 allowanceForAdjustment =
      expansion ? targetSupply.sub(floatSupply) : floatSupply.sub(targetSupply);

    // Cap Allowance per auction; e.g. with 10% of total supply => ~20% price move.
    uint256 allowanceByCap = floatSupply.percentageOf(capBasisPoint);

    return Math.min(allowanceForAdjustment, allowanceByCap);
  }

  /**
   * @notice Linear interpolation: start + (end - start) * (step/duration)
   * @dev For 150 steps, duration = 149, start / end can be in any format
   * as long as <= 10 ** 49.
   * @param start The starting value
   * @param end The ending value
   * @param step Number of blocks into interpolation
   * @param duration Total range
   */
  function lerp(
    uint256 start,
    uint256 end,
    uint256 step,
    uint256 duration
  ) internal pure returns (uint256 result) {
    require(duration != 0, "AuctionHouseMath/ZeroDuration");
    require(step <= duration, "AuctionHouseMath/InvalidStep");

    // Max value <= 2^256 / 10^27 of which 10^49 is.
    require(start <= 10**49, "AuctionHouseMath/StartTooLarge");
    require(end <= 10**49, "AuctionHouseMath/EndTooLarge");

    // 0 <= t <= PRECISE_UNIT
    uint256 t = step.divideDecimalRoundPrecise(duration);

    // result = start + (end - start) * t
    //        = end * t + start - start * t
    return
      result = end.multiplyDecimalRoundPrecise(t).add(start).sub(
        start.multiplyDecimalRoundPrecise(t)
      );
  }
}