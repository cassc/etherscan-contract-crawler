// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../external-lib/SafeDecimalMath.sol";

library BasketMath {
  using SafeMath for uint256;
  using SafeDecimalMath for uint256;

  // SafeDecimalMath.PRECISE_UNIT = 1e27
  uint256 internal constant MIN_TARGET_RATIO = 0.1e27;
  uint256 internal constant MAX_TARGET_RATIO = 2e27;

  /**
   * @dev bF = ( eS / (fS * tP) ) / Q
   * @param targetPriceInEth [e27] target price (tP).
   * @param ethStored [e18] denoting total eth stored in basket (eS).
   * @param floatSupply [e18] denoting total floatSupply (fS).
   * @param targetRatio [e27] target ratio (Q)
   * @return basketFactor an [e27] decimal (bF)
   */
  function calcBasketFactor(
    uint256 targetPriceInEth,
    uint256 ethStored,
    uint256 floatSupply,
    uint256 targetRatio
  ) internal pure returns (uint256 basketFactor) {
    // Note that targetRatio should already be checked on set
    assert(targetRatio >= MIN_TARGET_RATIO);
    assert(targetRatio <= MAX_TARGET_RATIO);
    uint256 floatValue =
      floatSupply.multiplyDecimalRoundPrecise(targetPriceInEth);
    uint256 basketRatio = ethStored.divideDecimalRoundPrecise(floatValue);
    return basketFactor = basketRatio.divideDecimalRoundPrecise(targetRatio);
  }
}