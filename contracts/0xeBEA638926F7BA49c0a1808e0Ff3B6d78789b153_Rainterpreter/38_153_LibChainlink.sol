// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {SafeCastUpgradeable as SafeCast} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "rain.math.fixedpoint/FixedPointDecimalScale.sol";

/// Thrown if a price is zero or negative as this is probably not anticipated or
/// useful for most users of a price feed. Of course there are use cases where
/// zero or negative _oracle values_ in general are useful, such as negative
/// temperatures from a thermometer, but these are unlikely to be useful _prices_
/// for assets. Zero value prices are likely to result in division by zero
/// downstream or giving away assets for free, negative price values could result
/// in even weirder behaviour due to token amounts being `uint256` and the
/// subtleties of signed vs. unsigned integer conversions.
/// @param price The price that is not a positive integer.
error NotPosIntPrice(int256 price);

/// Thrown when the updatedAt time from the Chainlink oracle is more than
/// staleAfter seconds prior to the current block timestamp. Prevents stale
/// prices from being used within the constraints set by the caller.
/// @param updatedAt The latest time the oracle was updated according to the
/// oracle.
/// @param staleAfter The maximum number of seconds the caller allows between
/// the block timestamp and the updated time.
error StalePrice(uint256 updatedAt, uint256 staleAfter);

library LibChainlink {
    using FixedPointDecimalScale for uint256;
    using SafeCast for int256;

    function price(
        address feed_,
        uint256 staleAfter_
    ) internal view returns (uint256) {
        (, int256 answer_, , uint256 updatedAt_, ) = AggregatorV3Interface(
            feed_
        ).latestRoundData();

        if (answer_ <= 0) {
            revert NotPosIntPrice(answer_);
        }

        // Checked time comparison ensures no updates from the future as that
        // would overflow, and no stale prices.
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp - updatedAt_ > staleAfter_) {
            revert StalePrice(updatedAt_, staleAfter_);
        }

        // Safely cast the answer to uint256 and scale it to 18 decimal FP.
        // We round up because reporting a non-zero price as zero can cause
        // issues downstream. This rounding up only happens if the values are
        // being scaled down.
        return
            answer_.toUint256().scale18(
                AggregatorV3Interface(feed_).decimals(),
                // Don't saturate, just round up.
                FLAG_ROUND_UP
            );
    }
}