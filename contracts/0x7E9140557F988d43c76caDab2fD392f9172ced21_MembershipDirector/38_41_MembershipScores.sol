// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {SafeCastUpgradeable as SafeCast} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "./MembershipFixedMath.sol";

using SafeCast for uint256;

library MembershipScores {
  uint256 internal constant GFI_MANTISSA = 1e18;
  uint256 internal constant USDC_MANTISSA = 1e6;
  uint256 internal constant USDC_TO_GFI_MANTISSA = GFI_MANTISSA / USDC_MANTISSA;

  /**
   * @notice Calculate a membership score given some amount of `gfi` and `capital`, along
   *  with some 𝝰 = `alphaNumerator` / `alphaDenominator`.
   * @param gfi amount of gfi (GFI, 1e18 decimal places)
   * @param capital amount of capital (USDC, 1e6 decimal places)
   * @param alphaNumerator alpha param numerator
   * @param alphaDenominator alpha param denominator
   * @return membership score with 1e18 decimal places
   *
   * @dev 𝝰 must be in the range [0, 1]
   */
  function calculateScore(
    uint256 gfi,
    uint256 capital,
    uint256 alphaNumerator,
    uint256 alphaDenominator
  ) internal pure returns (uint256) {
    // Convert capital to the same base units as GFI
    capital = capital * USDC_TO_GFI_MANTISSA;

    // Score function is:
    // gfi^𝝰 * capital^(1-𝝰)
    //    = capital * capital^(-𝝰) * gfi^𝝰
    //    = capital * (gfi / capital)^𝝰
    //    = capital * (e ^ (ln(gfi / capital))) ^ 𝝰
    //    = capital * e ^ (𝝰 * ln(gfi / capital))     (1)
    // or
    //    = capital / ( 1 / e ^ (𝝰 * ln(gfi / capital)))
    //    = capital / (e ^ (𝝰 * ln(gfi / capital)) ^ -1)
    //    = capital / e ^ (𝝰 * -1 * ln(gfi / capital))
    //    = capital / e ^ (𝝰 * ln(capital / gfi))     (2)
    //
    // To avoid overflows, use (1) when gfi < capital and
    // use (2) when capital < gfi

    assert(alphaNumerator <= alphaDenominator);

    // If any side is 0, exit early
    if (gfi == 0 || capital == 0) return 0;

    // If both sides are equal, we have:
    // gfi^𝝰 * capital^(1-𝝰)
    //    = gfi^𝝰 * gfi^(1-𝝰)
    //    = gfi^(𝝰 + 1 - 𝝰)     = gfi
    if (gfi == capital) return gfi;

    bool lessGFIThanCapital = gfi < capital;

    // (gfi / capital) or (capital / gfi), always in range (0, 1)
    int256 ratio = lessGFIThanCapital
      ? MembershipFixedMath.toFixed(gfi, capital)
      : MembershipFixedMath.toFixed(capital, gfi);

    // e ^ ( ln(ratio) * 𝝰 )
    int256 exponentiation = MembershipFixedMath.exp(
      (MembershipFixedMath.ln(ratio) * alphaNumerator.toInt256()) / alphaDenominator.toInt256()
    );

    if (lessGFIThanCapital) {
      // capital * e ^ (𝝰 * ln(gfi / capital))
      return MembershipFixedMath.uintMul(capital, exponentiation);
    }

    // capital / e ^ (𝝰 * ln(capital / gfi))
    return MembershipFixedMath.uintDiv(capital, exponentiation);
  }
}