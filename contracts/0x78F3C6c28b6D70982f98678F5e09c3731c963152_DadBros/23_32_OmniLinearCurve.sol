// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;



import { FixedPointMathLib } from "solmate/src/utils/FixedPointMathLib.sol";


library OmniLinearCurve {
    using FixedPointMathLib for uint256;


    struct OmniCurve {
        /// @notice last time the curve price was updated (resets decay).
        uint256 lastUpdate;
        /// @notice The current spot price for minting.
        uint128 spotPrice;
        /// @notice Price increase (e.g.: 1e18+1e16 == 0.01 increase) on every mint.
        uint128 priceDelta;
        /// @notice Daily price decay rate (1e18+1e16 == 1% decay) per day.
        uint128 priceDecay;
        /// @notice min price for minting radbros.
        uint128 minPrice;
    }

    /// @notice get the purchase price for a given number of items on a bonding curve.
    /// @param curve the bonding curve state
    /// @param numItems the number of items to purchase
    /// @return newSpotPrice the new spot price after the purchase
    /// @return inputValue the amount of ETH to send to purchase the items
    function getBuyInfo(
        OmniCurve memory curve,
        uint256 numItems
    ) internal view returns (uint128 newSpotPrice, uint256 inputValue) {
        if (curve.priceDelta == 0) {
            return (curve.spotPrice, curve.spotPrice * numItems);
        }

        uint256 decay = (curve.priceDecay * (block.timestamp - curve.lastUpdate)) / 14400;

        // For a linear curve, the spot price increases by delta for each item bought, and decreases for each day since the last update.
        uint256 newSpotPrice_ = curve.spotPrice + curve.priceDelta * numItems;
        if (decay >= newSpotPrice_) {
            decay = newSpotPrice_; // Prevent underflow
        }
        newSpotPrice_ -= decay;

        if (newSpotPrice_ < curve.minPrice) {
            newSpotPrice_ = curve.minPrice;
        } 

        // For an exponential curve, the spot price is multiplied by delta for each item bought
        require(newSpotPrice_ <= type(uint128).max, "SPOT_PRICE_OVERFLOW");
        newSpotPrice = uint128(newSpotPrice_);

        // If we buy n items, then the total cost is equal to:
        // (buy spot price) + (buy spot price + 1*delta) + (buy spot price + 2*delta) + ... + (buy spot price + (n-1)*delta)
        // This is equal to n*(buy spot price) + (delta)*(n*(n-1))/2
        // because we have n instances of buy spot price, and then we sum up from delta to (n-1)*delta
        inputValue = numItems * newSpotPrice + (numItems * (numItems - 1) * curve.priceDelta) / 2;
    }
}