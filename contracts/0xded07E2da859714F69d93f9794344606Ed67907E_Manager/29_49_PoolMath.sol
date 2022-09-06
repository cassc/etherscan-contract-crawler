// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Math.sol";
import "./UnsafeMath.sol";
import "./FullMath.sol";

library PoolMath {
    using Math for uint256;

    uint256 private constant Q72 = 0x1000000000000000000;
    uint256 private constant Q184 = 0x10000000000000000000000000000000000000000000000;

    // ----- sqrt price <> token amounts -----

    /// @dev Calculate amount0 delta when price moves from sqrtP0 to sqrtP1.
    /// i.e. Δx = L (√P0 - √P1) / (√P0 √P1)
    ///
    /// @dev Rounding rules:
    /// if sqrtP0 > sqrtP1 (price goes down):   => amt0 is input    => round away from zero
    /// if sqrtP0 < sqrtP1 (price goes up):     => amt0 is output   => round towards zero
    function calcAmt0FromSqrtP(
        uint128 sqrtP0,
        uint128 sqrtP1,
        uint128 liquidity
    ) internal pure returns (int256 amt0) {
        unchecked {
            bool priceUp = sqrtP1 > sqrtP0;
            if (priceUp) (sqrtP0, sqrtP1) = (sqrtP1, sqrtP0);

            uint256 num = uint256(liquidity) * (sqrtP0 - sqrtP1);
            uint256 denom = uint256(sqrtP0) * sqrtP1;
            amt0 = Math.toInt256(
                num < Q184
                    ? (priceUp ? (num << 72) / denom : UnsafeMath.ceilDiv(num << 72, denom))
                    : (priceUp ? FullMath.mulDiv(num, Q72, denom) : FullMath.mulDivRoundingUp(num, Q72, denom))
            );
            if (priceUp) amt0 *= -1;
        }
    }

    /// @dev Calculate amount1 delta when price moves from sqrtP0 to sqrtP1.
    /// i.e. Δy = L (√P0 - √P1)
    ///
    /// @dev Rounding rules:
    /// if sqrtP0 > sqrtP1 (price goes down):   => amt1 is output   => round towards zero
    /// if sqrtP0 < sqrtP1 (price goes up):     => amt1 is input    => round away from zero
    function calcAmt1FromSqrtP(
        uint128 sqrtP0,
        uint128 sqrtP1,
        uint128 liquidity
    ) internal pure returns (int256 amt1) {
        unchecked {
            bool priceDown = sqrtP1 < sqrtP0;
            if (priceDown) (sqrtP0, sqrtP1) = (sqrtP1, sqrtP0);

            uint256 num = uint256(liquidity) * (sqrtP1 - sqrtP0);
            amt1 = (priceDown ? num >> 72 : UnsafeMath.ceilDiv(num, Q72)).toInt256();
            if (priceDown) amt1 *= -1;
        }
    }

    /// @dev Calculate the new sqrt price after an amount0 delta.
    /// i.e. √P1 = L √P0 / (L + Δx * √P0)   if no overflow
    ///          = L / (L/√P0 + Δx)         otherwise
    ///
    /// @dev Rounding rules:
    /// if amt0 in:     price goes down => sqrtP1 rounded up for less price change for less amt1 out
    /// if amt0 out:    price goes up   => sqrtP1 rounded up for more price change for more amt1 in
    /// therefore:      sqrtP1 always rounded up
    function calcSqrtPFromAmt0(
        uint128 sqrtP0,
        uint128 liquidity,
        int256 amt0
    ) internal pure returns (uint128 sqrtP1) {
        unchecked {
            if (amt0 == 0) return sqrtP0;
            uint256 absAmt0 = uint256(amt0 < 0 ? -amt0 : amt0);
            uint256 product = absAmt0 * sqrtP0;
            uint256 liquidityX72 = uint256(liquidity) << 72;
            uint256 denom;

            if (amt0 > 0) {
                if ((product / absAmt0 == sqrtP0) && ((denom = liquidityX72 + product) >= liquidityX72)) {
                    // if product and denom don't overflow:
                    uint256 num = uint256(liquidity) * sqrtP0;
                    sqrtP1 = num < Q184
                        ? uint128(UnsafeMath.ceilDiv(num << 72, denom)) // denom > 0
                        : uint128(FullMath.mulDivRoundingUp(num, Q72, denom));
                } else {
                    // if either one overflows:
                    sqrtP1 = uint128(UnsafeMath.ceilDiv(liquidityX72, (liquidityX72 / sqrtP0).add(absAmt0))); // absAmt0 > 0
                }
            } else {
                // ensure product doesn't overflow and denom doesn't underflow
                require(product / absAmt0 == sqrtP0);
                require((denom = liquidityX72 - product) <= liquidityX72);
                require(denom != 0);
                uint256 num = uint256(liquidity) * sqrtP0;
                sqrtP1 = num < Q184
                    ? UnsafeMath.ceilDiv(num << 72, denom).toUint128()
                    : FullMath.mulDivRoundingUp(num, Q72, denom).toUint128();
            }
        }
    }

    /// @dev Calculate the new sqrt price after an amount1 delta.
    /// i.e. √P1 = √P0 + (Δy / L)
    ///
    /// @dev Rounding rules:
    /// if amt1 in:     price goes up   => sqrtP1 rounded down for less price delta for less amt0 out
    /// if amt1 out:    price goes down => sqrtP1 rounded down for more price delta for more amt0 in
    /// therefore:      sqrtP1 always rounded down
    function calcSqrtPFromAmt1(
        uint128 sqrtP0,
        uint128 liquidity,
        int256 amt1
    ) internal pure returns (uint128 sqrtP1) {
        unchecked {
            if (amt1 < 0) {
                // price moves down
                require(liquidity != 0);
                uint256 absAmt1 = uint256(-amt1);
                uint256 absAmt1DivL = absAmt1 < Q184
                    ? UnsafeMath.ceilDiv(absAmt1 * Q72, liquidity)
                    : FullMath.mulDivRoundingUp(absAmt1, Q72, liquidity);

                sqrtP1 = uint256(sqrtP0).sub(absAmt1DivL).toUint128();
            } else {
                // price moves up
                uint256 amt1DivL = uint256(amt1) < Q184
                    ? (uint256(amt1) * Q72) / liquidity
                    : FullMath.mulDiv(uint256(amt1), Q72, liquidity);

                sqrtP1 = uint256(sqrtP0).add(amt1DivL).toUint128();
            }
        }
    }

    // ----- liquidity <> token amounts -----

    /// @dev Calculate the amount{0,1} needed for the given liquidity change
    function calcAmtsForLiquidity(
        uint128 sqrtP,
        uint128 sqrtPLower,
        uint128 sqrtPUpper,
        int96 liquidityDeltaD8
    ) internal pure returns (uint256 amt0, uint256 amt1) {
        // we assume {sqrtP, sqrtPLower, sqrtPUpper} ≠ 0 and sqrtPLower < sqrtPUpper
        unchecked {
            // find the sqrt price at which liquidity is add/removed
            sqrtP = (sqrtP < sqrtPLower) ? sqrtPLower : (sqrtP > sqrtPUpper) ? sqrtPUpper : sqrtP;

            // calc amt{0,1} for the change of liquidity
            uint128 absL = uint128(uint96(liquidityDeltaD8 >= 0 ? liquidityDeltaD8 : -liquidityDeltaD8)) << 8;
            if (liquidityDeltaD8 >= 0) {
                // round up
                amt0 = uint256(calcAmt0FromSqrtP(sqrtPUpper, sqrtP, absL));
                amt1 = uint256(calcAmt1FromSqrtP(sqrtPLower, sqrtP, absL));
            } else {
                // round down
                amt0 = uint256(-calcAmt0FromSqrtP(sqrtP, sqrtPUpper, absL));
                amt1 = uint256(-calcAmt1FromSqrtP(sqrtP, sqrtPLower, absL));
            }
        }
    }

    /// @dev Calculate the max liquidity received if adding given token amounts to the tier.
    function calcLiquidityForAmts(
        uint128 sqrtP,
        uint128 sqrtPLower,
        uint128 sqrtPUpper,
        uint256 amt0,
        uint256 amt1
    ) internal pure returns (uint96 liquidityD8) {
        // we assume {sqrtP, sqrtPLower, sqrtPUpper} ≠ 0 and sqrtPLower < sqrtPUpper
        unchecked {
            uint256 liquidity;
            if (sqrtP <= sqrtPLower) {
                // L = Δx (√P0 √P1) / (√P0 - √P1)
                liquidity = FullMath.mulDiv(amt0, uint256(sqrtPLower) * sqrtPUpper, (sqrtPUpper - sqrtPLower) * Q72);
            } else if (sqrtP >= sqrtPUpper) {
                // L = Δy / (√P0 - √P1)
                liquidity = FullMath.mulDiv(amt1, Q72, sqrtPUpper - sqrtPLower);
            } else {
                uint256 liquidity0 = FullMath.mulDiv(amt0, uint256(sqrtP) * sqrtPUpper, (sqrtPUpper - sqrtP) * Q72);
                uint256 liquidity1 = FullMath.mulDiv(amt1, Q72, sqrtP - sqrtPLower);
                liquidity = (liquidity0 < liquidity1 ? liquidity0 : liquidity1);
            }
            liquidityD8 = (liquidity >> 8).toUint96();
        }
    }
}