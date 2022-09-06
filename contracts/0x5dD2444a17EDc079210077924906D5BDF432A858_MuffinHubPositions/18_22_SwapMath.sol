// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./FullMath.sol";
import "./PoolMath.sol";
import "./UnsafeMath.sol";
import "./Math.sol";
import "../Tiers.sol";

/// @dev Technically maximum number of fee tiers per pool.
/// @dev Declared at file level so other libraries/contracts can use it to define fixed-size array.
uint256 constant MAX_TIERS = 6;

library SwapMath {
    using Math for uint256;
    using Math for int256;

    int256 internal constant REJECTED = type(int256).max; // represents the tier is rejected for the swap
    int256 private constant MAX_UINT_DIV_1E10 = 0x6DF37F675EF6EADF5AB9A2072D44268D97DF837E6748956E5C6C2117;
    uint256 private constant Q72 = 0x1000000000000000000;

    /// @notice Given a set of tiers and the desired input amount, calculate the optimized input amount for each tier
    /// @param tiers        List of tiers
    /// @param isToken0     True if "amount" refers to token0
    /// @param amount       Desired input amount of the swap (must be positive)
    /// @param tierChoices  Bitmap to allow which tiers to swap
    /// @return amts        Optimized input amounts for tiers
    function calcTierAmtsIn(
        Tiers.Tier[] memory tiers,
        bool isToken0,
        int256 amount,
        uint256 tierChoices
    ) internal pure returns (int256[MAX_TIERS] memory amts) {
        assert(amount > 0);
        uint256[MAX_TIERS] memory lsg; // array of liquidity divided by sqrt gamma (UQ128)
        uint256[MAX_TIERS] memory res; // array of token reserve divided by gamma (UQ200)
        uint256 num; //    numerator of sqrt lambda (sum of UQ128)
        uint256 denom; //  denominator of sqrt lambda (sum of UQ200 + amount)

        unchecked {
            for (uint256 i; i < tiers.length; i++) {
                // reject unselected tiers
                if (tierChoices & (1 << i) == 0) {
                    amts[i] = REJECTED;
                    continue;
                }
                // calculate numerator and denominator of sqrt lamdba (lagrange multiplier)
                Tiers.Tier memory t = tiers[i];
                uint256 liquidity = uint256(t.liquidity);
                uint24 sqrtGamma = t.sqrtGamma;
                num += (lsg[i] = UnsafeMath.ceilDiv(liquidity * 1e5, sqrtGamma));
                denom += (res[i] = isToken0
                    ? UnsafeMath.ceilDiv(liquidity * Q72 * 1e10, uint256(t.sqrtPrice) * sqrtGamma * sqrtGamma)
                    : UnsafeMath.ceilDiv(liquidity * t.sqrtPrice, (Q72 * sqrtGamma * sqrtGamma) / 1e10));
            }
        }
        denom += uint256(amount);

        unchecked {
            // calculate input amts, then reject the tiers with negative input amts.
            // repeat until all input amts are non-negative
            uint256 product = denom * num;
            bool wontOverflow = (product / denom == num) && (product <= uint256(type(int256).max));
            for (uint256 i; i < tiers.length; ) {
                if (amts[i] != REJECTED) {
                    if (
                        (amts[i] = (
                            wontOverflow
                                ? int256((denom * lsg[i]) / num)
                                : FullMath.mulDiv(denom, lsg[i], num).toInt256()
                        ).sub(int256(res[i]))) < 0
                    ) {
                        amts[i] = REJECTED;
                        num -= lsg[i];
                        denom -= res[i];
                        i = 0;
                        continue;
                    }
                }
                i++;
            }
        }
    }

    /// @notice Given a set of tiers and the desired output amount, calculate the optimized output amount for each tier
    /// @param tiers        List of tiers
    /// @param isToken0     True if "amount" refers to token0
    /// @param amount       Desired output amount of the swap (must be negative)
    /// @param tierChoices  Bitmap to allow which tiers to swap
    /// @return amts        Optimized output amounts for tiers
    function calcTierAmtsOut(
        Tiers.Tier[] memory tiers,
        bool isToken0,
        int256 amount,
        uint256 tierChoices
    ) internal pure returns (int256[MAX_TIERS] memory amts) {
        assert(amount < 0);
        uint256[MAX_TIERS] memory lsg; // array of liquidity divided by sqrt fee (UQ128)
        uint256[MAX_TIERS] memory res; // array of token reserve (UQ200)
        uint256 num; //   numerator of sqrt lambda (sum of UQ128)
        int256 denom; //  denominator of sqrt lambda (sum of UQ200 - amount)

        unchecked {
            for (uint256 i; i < tiers.length; i++) {
                // reject unselected tiers
                if (tierChoices & (1 << i) == 0) {
                    amts[i] = REJECTED;
                    continue;
                }
                // calculate numerator and denominator of sqrt lamdba (lagrange multiplier)
                Tiers.Tier memory t = tiers[i];
                uint256 liquidity = uint256(t.liquidity);
                num += (lsg[i] = (liquidity * 1e5) / t.sqrtGamma);
                denom += int256(res[i] = isToken0 ? (liquidity << 72) / t.sqrtPrice : (liquidity * t.sqrtPrice) >> 72);
            }
        }
        denom += amount;

        unchecked {
            // calculate output amts, then reject the tiers with positive output amts.
            // repeat until all output amts are non-positive
            for (uint256 i; i < tiers.length; ) {
                if (amts[i] != REJECTED) {
                    if ((amts[i] = _ceilMulDiv(denom, lsg[i], num).sub(int256(res[i]))) > 0) {
                        amts[i] = REJECTED;
                        num -= lsg[i];
                        denom -= int256(res[i]);
                        i = 0;
                        continue;
                    }
                }
                i++;
            }
        }
    }

    function _ceilMulDiv(
        int256 x,
        uint256 y,
        uint256 denom
    ) internal pure returns (int256 z) {
        unchecked {
            z = x < 0
                ? -FullMath.mulDiv(uint256(-x), y, denom).toInt256()
                : FullMath.mulDivRoundingUp(uint256(x), y, denom).toInt256();
        }
    }

    /// @dev Calculate a single swap step. We process the swap as much as possible until the tier's price hits the next tick.
    /// @param isToken0     True if "amount" refers to token0
    /// @param exactIn      True if the swap is specified with an input token amount (instead of an output)
    /// @param amount       The swap amount (positive: token in; negative token out)
    /// @param sqrtP        The sqrt price currently
    /// @param sqrtPTick    The sqrt price of the next crossing tick
    /// @param liquidity    The current liqudity amount
    /// @param sqrtGamma    The sqrt of (1 - percentage swap fee) (precision: 1e5)
    /// @return amtA        The delta of the pool's tokenA balance (tokenA means token0 if `isToken0` is true, vice versa)
    /// @return amtB        The delta of the pool's tokenB balance (tokenB means the opposite token of tokenA)
    /// @return sqrtPNew    The new sqrt price after the swap
    /// @return feeAmt      The fee amount charged for this swap
    function computeStep(
        bool isToken0,
        bool exactIn,
        int256 amount,
        uint128 sqrtP,
        uint128 sqrtPTick,
        uint128 liquidity,
        uint24 sqrtGamma
    )
        internal
        pure
        returns (
            int256 amtA,
            int256 amtB,
            uint128 sqrtPNew,
            uint256 feeAmt
        )
    {
        unchecked {
            amtA = amount;
            int256 amtInExclFee; // i.e. input amt excluding fee

            // calculate amt needed to reach to the tick
            int256 amtTick = isToken0
                ? PoolMath.calcAmt0FromSqrtP(sqrtP, sqrtPTick, liquidity)
                : PoolMath.calcAmt1FromSqrtP(sqrtP, sqrtPTick, liquidity);

            // calculate percentage fee (precision: 1e10)
            uint256 gamma = uint256(sqrtGamma) * sqrtGamma;

            if (exactIn) {
                // amtA: the input amt (positive)
                // amtB: the output amt (negative)

                // calculate input amt excluding fee
                amtInExclFee = amtA < MAX_UINT_DIV_1E10
                    ? int256((uint256(amtA) * gamma) / 1e10)
                    : int256((uint256(amtA) / 1e10) * gamma);

                // check if crossing tick
                if (amtInExclFee < amtTick) {
                    // no cross tick: calculate new sqrt price after swap
                    sqrtPNew = isToken0
                        ? PoolMath.calcSqrtPFromAmt0(sqrtP, liquidity, amtInExclFee)
                        : PoolMath.calcSqrtPFromAmt1(sqrtP, liquidity, amtInExclFee);
                } else {
                    // cross tick: replace new sqrt price and input amt
                    sqrtPNew = sqrtPTick;
                    amtInExclFee = amtTick;

                    // re-calculate input amt _including_ fee
                    amtA = (
                        amtInExclFee < MAX_UINT_DIV_1E10
                            ? UnsafeMath.ceilDiv(uint256(amtInExclFee) * 1e10, gamma)
                            : UnsafeMath.ceilDiv(uint256(amtInExclFee), gamma) * 1e10
                    ).toInt256();
                }

                // calculate output amt
                amtB = isToken0
                    ? PoolMath.calcAmt1FromSqrtP(sqrtP, sqrtPNew, liquidity)
                    : PoolMath.calcAmt0FromSqrtP(sqrtP, sqrtPNew, liquidity);

                // calculate fee amt
                feeAmt = uint256(amtA - amtInExclFee);
            } else {
                // amtA: the output amt (negative)
                // amtB: the input amt (positive)

                // check if crossing tick
                if (amtA > amtTick) {
                    // no cross tick: calculate new sqrt price after swap
                    sqrtPNew = isToken0
                        ? PoolMath.calcSqrtPFromAmt0(sqrtP, liquidity, amtA)
                        : PoolMath.calcSqrtPFromAmt1(sqrtP, liquidity, amtA);
                } else {
                    // cross tick: replace new sqrt price and output amt
                    sqrtPNew = sqrtPTick;
                    amtA = amtTick;
                }

                // calculate input amt excluding fee
                amtInExclFee = isToken0
                    ? PoolMath.calcAmt1FromSqrtP(sqrtP, sqrtPNew, liquidity)
                    : PoolMath.calcAmt0FromSqrtP(sqrtP, sqrtPNew, liquidity);

                // calculate input amt
                amtB = (
                    amtInExclFee < MAX_UINT_DIV_1E10
                        ? UnsafeMath.ceilDiv(uint256(amtInExclFee) * 1e10, gamma)
                        : UnsafeMath.ceilDiv(uint256(amtInExclFee), gamma) * 1e10
                ).toInt256();

                // calculate fee amt
                feeAmt = uint256(amtB - amtInExclFee);
            }

            // reject tier if zero input amt and not crossing tick
            if (amtInExclFee == 0 && sqrtPNew != sqrtPTick) {
                amtA = REJECTED;
                amtB = 0;
                sqrtPNew = sqrtP;
                feeAmt = 0;
            }
        }
    }
}