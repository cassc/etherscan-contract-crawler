// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IToken.sol";

library PriceLimitLib {
    uint public constant PRICE_LIMIT_MULTIPLIER = 1e8;

    function isPriceOutsideLimit(
        uint priceNumerator,
        uint priceDenominator,
        uint8 numeratorDecimals,
        uint8 denominatorDecimals,
        uint lowerLimit,
        uint upperLimit
    ) public view returns (bool) {
        if (denominatorDecimals > numeratorDecimals) {
            priceNumerator *= 10**(denominatorDecimals - numeratorDecimals);
        } else if (numeratorDecimals > denominatorDecimals) {
            priceDenominator *= 10**(numeratorDecimals - denominatorDecimals);
        }

        // priceFloat = priceNumerator / priceDenominator
        // stopLossPriceFloat = position.stopLossPrice / POSITION_PRICE_LIMITS_MULTIPLIER
        // if
        // priceNumerator / priceDenominator > position.stopLossPrice / POSITION_PRICE_LIMITS_MULTIPLIER
        // then
        // priceNumerator * POSITION_PRICE_LIMITS_MULTIPLIER > position.stopLossPrice * priceDenominator

        if (lowerLimit != 0 && priceNumerator * PRICE_LIMIT_MULTIPLIER < lowerLimit * priceDenominator) {
            return true;
        }

        if (upperLimit != 0 && priceNumerator * PRICE_LIMIT_MULTIPLIER > upperLimit * priceDenominator) {
            return true;
        }

        return false;
    }
}