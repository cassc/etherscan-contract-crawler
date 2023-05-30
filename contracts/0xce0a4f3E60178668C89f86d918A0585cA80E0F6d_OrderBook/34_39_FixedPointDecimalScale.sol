// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./FixedPointDecimalConstants.sol";

/// @title FixedPointDecimalScale
/// @notice Tools to scale unsigned values to/from 18 decimal fixed point
/// representation.
///
/// Overflows error and underflows are rounded up or down explicitly.
///
/// The max uint256 as decimal is roughly 1e77 so scaling values comparable to
/// 1e18 is unlikely to ever overflow in most contexts. For a typical use case
/// involving tokens, the entire supply of a token rescaled up a full 18 decimals
/// would still put it "only" in the region of ~1e40 which has a full 30 orders
/// of magnitude buffer before running into saturation issues. However, there's
/// no theoretical reason that a token or any other use case couldn't use large
/// numbers or extremely precise decimals that would push this library to
/// overflow point, so it MUST be treated with caution around the edge cases.
///
/// Scaling down ANY fixed point decimal also reduces the precision which can
/// lead to  dust or in the worst case trapped funds if subsequent subtraction
/// overflows a rounded-down number. Consider using saturating subtraction for
/// safety against previously downscaled values, and whether trapped dust is a
/// significant issue. If you need to retain full/arbitrary precision in the case
/// of downscaling DO NOT use this library.
///
/// All rescaling and/or division operations in this library require a rounding
/// flag. This allows and forces the caller to specify where dust sits due to
/// rounding. For example the caller could round up when taking tokens from
/// `msg.sender` and round down when returning them, ensuring that any dust in
/// the round trip accumulates in the contract rather than opening an exploit or
/// reverting and trapping all funds. This is exactly how the ERC4626 vault spec
/// handles dust and is a good reference point in general. Typically the contract
/// holding tokens and non-interactive participants should be favoured by
/// rounding calculations rather than active participants. This is because we
/// assume that an active participant, e.g. `msg.sender`, knowns something we
/// don't and is carefully crafting an attack, so we are most conservative and
/// suspicious of their inputs and actions.
library FixedPointDecimalScale {
    /// Scales `a_` up by a specified number of decimals.
    /// @param a_ The number to scale up.
    /// @param scaleUpBy_ Number of orders of magnitude to scale `b_` up by.
    /// Errors if overflows.
    /// @return b_ `a_` scaled up by `scaleUpBy_`.
    function scaleUp(uint256 a_, uint256 scaleUpBy_) internal pure returns (uint256 b_) {
        // Checked power is expensive so don't do that.
        unchecked {
            b_ = 10 ** scaleUpBy_;
        }
        b_ = a_ * b_;

        // We know exactly when 10 ** X overflows so replay the checked version
        // to get the standard Solidity overflow behaviour. The branching logic
        // here is still ~230 gas cheaper than unconditionally running the
        // overflow checks. We're optimising for standardisation rather than gas
        // in the unhappy revert case.
        if (scaleUpBy_ >= OVERFLOW_RESCALE_OOMS) {
            b_ = a_ == 0 ? 0 : 10 ** scaleUpBy_;
        }
    }

    /// Identical to `scaleUp` but saturates instead of reverting on overflow.
    /// @param a_ As per `scaleUp`.
    /// @param scaleUpBy_ As per `scaleUp`.
    /// @return c_ As per `scaleUp` but saturates as `type(uint256).max` on
    /// overflow.
    function scaleUpSaturating(uint256 a_, uint256 scaleUpBy_) internal pure returns (uint256 c_) {
        unchecked {
            if (scaleUpBy_ >= OVERFLOW_RESCALE_OOMS) {
                c_ = a_ == 0 ? 0 : type(uint256).max;
            } else {
                // Adapted from saturatingMath.
                // Inlining everything here saves ~250-300+ gas relative to slow.
                uint256 b_ = 10 ** scaleUpBy_;
                c_ = a_ * b_;
                // Checking b_ here allows us to skip an "is zero" check because even
                // 10 ** 0 = 1, so we have a positive lower bound on b_.
                c_ = c_ / b_ == a_ ? c_ : type(uint256).max;
            }
        }
    }

    /// Scales `a_` down by a specified number of decimals, rounding in the
    /// specified direction. Used internally by several other functions in this
    /// lib.
    /// @param a_ The number to scale down.
    /// @param scaleDownBy_ Number of orders of magnitude to scale `a_` down by.
    /// Overflows if greater than 77.
    /// @return c_ `a_` scaled down by `scaleDownBy_` and rounded.
    function scaleDown(uint256 a_, uint256 scaleDownBy_) internal pure returns (uint256) {
        unchecked {
            return scaleDownBy_ >= OVERFLOW_RESCALE_OOMS ? 0 : a_ / (10 ** scaleDownBy_);
        }
    }

    function scaleDownRoundUp(uint256 a_, uint256 scaleDownBy_) internal pure returns (uint256 c_) {
        unchecked {
            if (scaleDownBy_ >= OVERFLOW_RESCALE_OOMS) {
                c_ = a_ == 0 ? 0 : 1;
            } else {
                uint256 b_ = 10 ** scaleDownBy_;
                c_ = a_ / b_;

                // Intentionally doing a divide before multiply here to detect
                // the need to round up.
                //slither-disable-next-line divide-before-multiply
                if (a_ != c_ * b_) {
                    c_ += 1;
                }
            }
        }
    }

    /// Scale a fixed point decimal of some scale factor to 18 decimals.
    /// @param a_ Some fixed point decimal value.
    /// @param decimals_ The number of fixed decimals of `a_`.
    /// @param flags_ Controls rounding and saturation.
    /// @return `a_` scaled to 18 decimals.
    function scale18(uint256 a_, uint256 decimals_, uint256 flags_) internal pure returns (uint256) {
        unchecked {
            if (FIXED_POINT_DECIMALS > decimals_) {
                uint256 scaleUpBy_ = FIXED_POINT_DECIMALS - decimals_;
                if (flags_ & FLAG_SATURATE > 0) {
                    return scaleUpSaturating(a_, scaleUpBy_);
                } else {
                    return scaleUp(a_, scaleUpBy_);
                }
            } else if (decimals_ > FIXED_POINT_DECIMALS) {
                uint256 scaleDownBy_ = decimals_ - FIXED_POINT_DECIMALS;
                if (flags_ & FLAG_ROUND_UP > 0) {
                    return scaleDownRoundUp(a_, scaleDownBy_);
                } else {
                    return scaleDown(a_, scaleDownBy_);
                }
            } else {
                return a_;
            }
        }
    }

    /// Scale an 18 decimal fixed point value to some other scale.
    /// Exactly the inverse behaviour of `scale18`. Where `scale18` would scale
    /// up, `scaleN` scales down, and vice versa.
    /// @param a_ An 18 decimal fixed point number.
    /// @param targetDecimals_ The new scale of `a_`.
    /// @param flags_ Controls rounding and saturation.
    /// @return `a_` rescaled from 18 to `targetDecimals_`.
    function scaleN(uint256 a_, uint256 targetDecimals_, uint256 flags_) internal pure returns (uint256) {
        unchecked {
            if (FIXED_POINT_DECIMALS > targetDecimals_) {
                uint256 scaleDownBy_ = FIXED_POINT_DECIMALS - targetDecimals_;
                if (flags_ & FLAG_ROUND_UP > 0) {
                    return scaleDownRoundUp(a_, scaleDownBy_);
                } else {
                    return scaleDown(a_, scaleDownBy_);
                }
            } else if (targetDecimals_ > FIXED_POINT_DECIMALS) {
                uint256 scaleUpBy_ = targetDecimals_ - FIXED_POINT_DECIMALS;
                if (flags_ & FLAG_SATURATE > 0) {
                    return scaleUpSaturating(a_, scaleUpBy_);
                } else {
                    return scaleUp(a_, scaleUpBy_);
                }
            } else {
                return a_;
            }
        }
    }

    /// Scale a fixed point up or down by `scaleBy_` orders of magnitude.
    /// Notably `scaleBy` is a SIGNED integer so scaling down by negative OOMS
    /// is supported.
    /// @param a_ Some integer of any scale.
    /// @param scaleBy_ OOMs to scale `a_` up or down by. This is a SIGNED int8
    /// which means it can be negative, and also means that sign extension MUST
    /// be considered if changing it to another type.
    /// @param flags_ Controls rounding and saturating.
    /// @return `a_` rescaled according to `scaleBy_`.
    function scaleBy(uint256 a_, int8 scaleBy_, uint256 flags_) internal pure returns (uint256) {
        unchecked {
            if (scaleBy_ > 0) {
                if (flags_ & FLAG_SATURATE > 0) {
                    return scaleUpSaturating(a_, uint8(scaleBy_));
                } else {
                    return scaleUp(a_, uint8(scaleBy_));
                }
            } else if (scaleBy_ < 0) {
                // We know that scaleBy_ is negative here, so we can convert it
                // to an absolute value with bitwise NOT + 1.
                // This is slightly less gas than multiplying by negative 1 and
                // casting it, and handles the case of -128 without overflow.
                uint8 scaleDownBy_ = uint8(~scaleBy_) + 1;
                if (flags_ & FLAG_ROUND_UP > 0) {
                    return scaleDownRoundUp(a_, scaleDownBy_);
                } else {
                    return scaleDown(a_, scaleDownBy_);
                }
            } else {
                return a_;
            }
        }
    }

    /// Scale an 18 decimal fixed point ratio of a_:b_ according to the decimals
    /// of a and b that each MAY NOT be 18.
    /// i.e. a subsequent call to `a_.fixedPointMul(ratio_)` would yield the
    /// value that it would have as though `a_` and `b_` were both 18 decimals
    /// and we hadn't rescaled the ratio.
    ///
    /// This is similar to `scaleBy` that calcualates the OOMs to scale by as
    /// `bDecimals_ - aDecimals_`.
    ///
    /// @param ratio_ The ratio to be scaled.
    /// @param aDecimals_ The decimals of the ratio numerator.
    /// @param bDecimals_ The decimals of the ratio denominator.
    /// @param flags_ Controls rounding and saturating.
    function scaleRatio(uint256 ratio_, uint8 aDecimals_, uint8 bDecimals_, uint256 flags_)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            if (bDecimals_ > aDecimals_) {
                uint8 scaleUpBy_ = bDecimals_ - aDecimals_;
                if (flags_ & FLAG_SATURATE > 0) {
                    return scaleUpSaturating(ratio_, scaleUpBy_);
                }
                else {
                    return scaleUp(ratio_, scaleUpBy_);
                }
            }
            else if (aDecimals_ > bDecimals_) {
                uint8 scaleDownBy_ = aDecimals_ - bDecimals_;
                if (flags_ & FLAG_ROUND_UP > 0) {
                    return scaleDownRoundUp(ratio_, scaleDownBy_);
                }
                else {
                    return scaleDown(ratio_, scaleDownBy_);
                }
            }
            else {
                return ratio_;
            }
        }
    }
}