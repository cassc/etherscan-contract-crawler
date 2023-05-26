// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {SafeCastUpgradeable as SafeCast} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "../math/SaturatingMath.sol";

/// @dev The scale of all fixed point math. This is adopting the conventions of
/// both ETH (wei) and most ERC20 tokens, so is hopefully uncontroversial.
uint256 constant FP_DECIMALS = 18;
/// @dev The number `1` in the standard fixed point math scaling. Most of the
/// differences between fixed point math and regular math is multiplying or
/// dividing by `ONE` after the appropriate scaling has been applied.
uint256 constant FP_ONE = 1e18;

/// @title FixedPointMath
/// @notice Sometimes we want to do math with decimal values but all we have
/// are integers, typically uint256 integers. Floats are very complex so we
/// don't attempt to simulate them. Instead we provide a standard definition of
/// "one" as 10 ** 18 and scale everything up/down to this as fixed point math.
///
/// Overflows SATURATE rather than error, e.g. scaling max uint256 up will result
/// in max uint256. The max uint256 as decimal is roughly 1e77 so scaling values
/// comparable to 1e18 is unlikely to ever saturate in practise. For a typical
/// use case involving tokens, the entire supply of a token rescaled up a full
/// 18 decimals would still put it "only" in the region of ~1e40 which has a full
/// 30 orders of magnitude buffer before running into saturation issues. However,
/// there's no theoretical reason that a token or any other use case couldn't use
/// large numbers or extremely precise decimals that would push this library to
/// saturation point, so it MUST be treated with caution around the edge cases.
///
/// One case where values could come near the saturation/overflow point is phantom
/// overflow. This is where an overflow happens during the internal logic of some
/// operation like "fixed point multiplication" even though the final result fits
/// within uint256. The fixed point multiplication and division functions are
/// thin wrappers around Open Zeppelin's `mulDiv` function, that handles phantom
/// overflow, reducing the problems of rescaling overflow/saturation to the input
/// and output range rather than to the internal implementation details. For this
/// library that gives an additional full 18 orders of magnitude for safe fixed
/// point multiplication operations.
///
/// Scaling down ANY fixed point decimal also reduces the precision which can
/// lead to  dust or in the worst case trapped funds if subsequent subtraction
/// overflows a rounded-down number. Consider using saturating subtraction for
/// safety against previously downscaled values, and whether trapped dust is a
/// significant issue. If you need to retain full/arbitrary precision in the case
/// of downscaling DO NOT use this library.
///
/// All rescaling and/or division operations in this library require the rounding
/// flag from Open Zeppelin math. This allows and forces the caller to specify
/// where dust sits due to rounding. For example the caller could round up when
/// taking tokens from `msg.sender` and round down when returning them, ensuring
/// that any dust in the round trip accumulates in the contract rather than
/// opening an exploit or reverting and trapping all funds. This is exactly how
/// the ERC4626 vault spec handles dust and is a good reference point in general.
/// Typically the contract holding tokens and non-interactive participants should
/// be favoured by rounding calculations rather than active participants. This is
/// because we assume that an active participant, e.g. `msg.sender`, knowns
/// something we don't and is carefully crafting an attack, so we are most
/// conservative and suspicious of their inputs and actions.
library LibFixedPointMath {
    using Math for uint256;
    using SafeCast for int256;
    using SaturatingMath for uint256;

    /// Scale a fixed point decimal of some scale factor to match `DECIMALS`.
    /// @param a_ Some fixed point decimal value.
    /// @param aDecimals_ The number of fixed decimals of `a_`.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    /// @return `a_` scaled to match `DECIMALS`.
    function scale18(
        uint256 a_,
        uint256 aDecimals_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        uint256 decimals_;
        if (FP_DECIMALS == aDecimals_) {
            return a_;
        } else if (FP_DECIMALS > aDecimals_) {
            unchecked {
                decimals_ = FP_DECIMALS - aDecimals_;
            }
            return a_.saturatingMul(10 ** decimals_);
        } else {
            unchecked {
                decimals_ = aDecimals_ - FP_DECIMALS;
            }
            return scaleDown(a_, decimals_, rounding_);
        }
    }

    /// Scale a fixed point decimals of `DECIMALS` to some other scale.
    /// @param a_ A `DECIMALS` fixed point decimals.
    /// @param targetDecimals_ The new scale of `a_`.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    /// @return `a_` rescaled from `DECIMALS` to `targetDecimals_`.
    function scaleN(
        uint256 a_,
        uint256 targetDecimals_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        uint256 decimals_;
        if (targetDecimals_ == FP_DECIMALS) {
            return a_;
        } else if (FP_DECIMALS > targetDecimals_) {
            unchecked {
                decimals_ = FP_DECIMALS - targetDecimals_;
            }
            return scaleDown(a_, decimals_, rounding_);
        } else {
            unchecked {
                decimals_ = targetDecimals_ - FP_DECIMALS;
            }
            return a_.saturatingMul(10 ** decimals_);
        }
    }

    /// Scale a fixed point decimals of `DECIMALS` that represents a ratio of
    /// a_:b_ according to the decimals of a and b that MAY NOT be `DECIMALS`.
    /// i.e. a subsequent call to `a_.fixedPointMul(ratio_)` would yield the value
    /// that it would have as though `a_` and `b_` were both `DECIMALS` and we
    /// hadn't rescaled the ratio.
    /// @param ratio_ The ratio to be scaled.
    /// @param aDecimals_ The decimals of the ratio numerator.
    /// @param bDecimals_ The decimals of the ratio denominator.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    function scaleRatio(
        uint256 ratio_,
        uint256 aDecimals_,
        uint256 bDecimals_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        return
            scaleBy(
                ratio_,
                (int256(bDecimals_) - int256(aDecimals_)).toInt8(),
                rounding_
            );
    }

    /// Scale a fixed point up or down by `scaleBy_` orders of magnitude.
    /// The caller MUST ensure the end result matches `DECIMALS` if other
    /// functions in this library are to work correctly.
    /// Notably `scaleBy` is a SIGNED integer so scaling down by negative OOMS
    /// is supported.
    /// @param a_ Some integer of any scale.
    /// @param scaleBy_ OOMs to scale `a_` up or down by. This is a SIGNED int8
    /// which means it can be negative, and also means that sign extension MUST
    /// be considered if changing it to another type.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    /// @return `a_` rescaled according to `scaleBy_`.
    function scaleBy(
        uint256 a_,
        int8 scaleBy_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        if (scaleBy_ == 0) {
            return a_;
        } else if (scaleBy_ > 0) {
            return a_.saturatingMul(10 ** uint8(scaleBy_));
        } else {
            uint256 scaleDownBy_;
            unchecked {
                scaleDownBy_ = uint8(-1 * scaleBy_);
            }
            return scaleDown(a_, scaleDownBy_, rounding_);
        }
    }

    /// Scales `a_` down by a specified number of decimals, rounding in the
    /// specified direction. Used internally by several other functions in this
    /// lib.
    /// @param a_ The number to scale down.
    /// @param scaleDownBy_ Number of orders of magnitude to scale `a_` down by.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    /// @return `a_` scaled down by `scaleDownBy_` and rounded.
    function scaleDown(
        uint256 a_,
        uint256 scaleDownBy_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        uint256 b_ = 10 ** scaleDownBy_;
        uint256 scaled_ = a_ / b_;
        if (rounding_ == Math.Rounding.Up && a_ != scaled_ * b_) {
            scaled_ += 1;
        }
        return scaled_;
    }

    /// Fixed point multiplication in native scale decimals.
    /// Both `a_` and `b_` MUST be `DECIMALS` fixed point decimals.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    /// @return `a_` multiplied by `b_` to `DECIMALS` fixed point decimals.
    function fixedPointMul(
        uint256 a_,
        uint256 b_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        return a_.mulDiv(b_, FP_ONE, rounding_);
    }

    /// Fixed point division in native scale decimals.
    /// Both `a_` and `b_` MUST be `DECIMALS` fixed point decimals.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    /// @return `a_` divided by `b_` to `DECIMALS` fixed point decimals.
    function fixedPointDiv(
        uint256 a_,
        uint256 b_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        return a_.mulDiv(FP_ONE, b_, rounding_);
    }
}