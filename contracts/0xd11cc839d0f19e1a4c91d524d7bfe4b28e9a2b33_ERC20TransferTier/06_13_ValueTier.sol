// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {ITier} from "./ITier.sol";
import "./libraries/TierConstants.sol";

import "../sstore2/SSTORE2.sol";

/// @title ValueTier
///
/// @dev A contract that is `ValueTier` expects to derive tiers from explicit
/// values. For example an address must send or hold an amount of something to
/// reach a given tier.
/// Anything with predefined values that map to tiers can be a `ValueTier`.
///
/// Note that `ValueTier` does NOT implement `ITier`.
/// `ValueTier` does include state however, to track the `tierValues` so is not
/// a library.
contract ValueTier {
    /// TODO: Typescript errors on uint256[8] so can't include tierValues here.
    /// @param sender The `msg.sender` initializing value tier.
    /// @param pointer Pointer to the uint256[8] values.
    event InitializeValueTier(address sender, address pointer);

    /// Pointer to the uint256[8] values.
    address private tierValuesPointer;

    /// Set the `tierValues` on construction to be referenced immutably.
    function initializeValueTier(uint256[8] memory tierValues_) internal {
        // Reinitialization is a bug.
        assert(tierValuesPointer == address(0));
        unchecked {
            uint256 accumulator_ = 0;
            for (uint256 i_ = 0; i_ < 8; i_++) {
                require(
                    tierValues_[i_] >= accumulator_,
                    "OUT_OF_ORDER_TIER_VALUES"
                );
                accumulator_ = tierValues_[i_];
            }
        }
        address tierValuesPointer_ = SSTORE2.write(abi.encode(tierValues_));
        emit InitializeValueTier(msg.sender, tierValuesPointer_);
        tierValuesPointer = tierValuesPointer_;
    }

    /// Complements the default solidity accessor for `tierValues`.
    /// Returns all the values in a list rather than requiring an index be
    /// specified.
    /// @return tierValues_ The immutable `tierValues`.
    function tierValues() public view returns (uint256[8] memory tierValues_) {
        return abi.decode(SSTORE2.read(tierValuesPointer), (uint256[8]));
    }

    /// Converts a Tier to the minimum value it requires.
    /// tier 0 is always value 0 as it is the fallback.
    /// @param tier_ The Tier to convert to a value.
    function tierToValue(uint256[8] memory tierValues_, uint256 tier_)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            return tier_ > TierConstants.TIER_ZERO ? tierValues_[tier_ - 1] : 0;
        }
    }

    /// Converts a value to the maximum Tier it qualifies for.
    /// @param value_ The value to convert to a tier.
    function valueToTier(uint256[8] memory tierValues_, uint256 value_)
        internal
        pure
        returns (uint256)
    {
        for (uint256 i_ = 0; i_ < TierConstants.MAX_TIER; i_++) {
            if (value_ < tierValues_[i_]) {
                return i_;
            }
        }
        return TierConstants.MAX_TIER;
    }
}