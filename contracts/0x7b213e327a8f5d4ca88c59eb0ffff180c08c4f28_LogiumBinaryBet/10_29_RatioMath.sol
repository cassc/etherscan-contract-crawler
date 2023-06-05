// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

/// @title Ratio Math - helper function for calculations related to ratios
/// @notice ratio specifies proportion of issuer to trader stakes
/// - positive ratio: issuer puts "ratio", trader puts "1"
/// - negative ratio: issuer puts "1", trader puts "ratio"
/// zero is an invalid value
///
/// Amount is the smallest unit of a bet. It's equal to min(issuerStake, traderStake) which avoids division.
/// For a given ratio total stake is always amount*(abs(ratio)+1)
library RatioMath {
    /// @notice Calculate issuerStake and traderStake for a given amount of bet and ratio
    /// @param amount number of smallest bet units (=min(issuerStake, traderStake))
    /// @param ratio bet ratio
    /// @return pair (issuerStake, traderStake)
    function priceFromRatio(uint256 amount, int24 ratio)
        internal
        pure
        returns (uint256, uint256)
    {
        require(ratio != 0, "Ratio can't be zero");
        if (ratio > 0) {
            return (amount * (uint24(ratio)), amount);
        } else {
            return (amount, amount * (uint24(-ratio)));
        }
    }

    function issuerToTrader(uint128 issuer, int24 ratio)
        internal
        pure
        returns (uint128)
    {
        require(ratio != 0, "Ratio can't be zero");
        if (ratio > 0) return issuer / uint24(ratio);
        else {
            return issuer * uint24(-ratio);
        }
    }

    /// @notice Calculates totalStake of a bet based on amount issued and ratio
    /// @param amount number of smallest bet units issued in a bet
    /// @param ratio bet ratio
    /// @return totalStake = issuerStake + traderStake
    function totalStake(uint256 amount, int24 ratio)
        internal
        pure
        returns (uint256)
    {
        require(ratio != 0, "Ratio can't be zero");
        if (ratio > 0) {
            return amount * (uint24(ratio) + 1);
        } else {
            return amount * (uint24(-ratio) + 1);
        }
    }

    function totalStakeToPrice(uint256 total, int24 ratio)
        internal
        pure
        returns (uint256 issuerPrice, uint256 traderPrice)
    {
        require(ratio != 0, "Ratio can't be zero");
        uint256 totalMultiplier;
        if (ratio > 0) {
            totalMultiplier = (uint256(uint24(ratio)) + 1);
        } else {
            totalMultiplier = (uint256(uint24(-ratio)) + 1);
        }
        uint256 extra = total % totalMultiplier;
        uint256 baseUnits = total / totalMultiplier;
        (issuerPrice, traderPrice) = priceFromRatio(baseUnits, ratio);
        traderPrice += extra;
    }
}