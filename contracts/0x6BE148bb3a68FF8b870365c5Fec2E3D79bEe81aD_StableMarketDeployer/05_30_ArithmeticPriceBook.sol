// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "../Errors.sol";
import "../interfaces/CloberStableMarketDeployer.sol";

abstract contract ArithmeticPriceBook {
    uint128 private immutable _a;
    uint128 private immutable _d;

    constructor(uint128 a, uint128 d) {
        _a = a;
        _d = d;

        if (d == 0 || type(uint16).max * d > type(uint128).max - a) {
            revert Errors.CloberError(Errors.INVALID_COEFFICIENTS);
        }
    }

    function _indexToPrice(uint16 priceIndex) internal view virtual returns (uint128) {
        return _a + _d * priceIndex;
    }

    function _priceToIndex(uint128 price, bool roundingUp)
        internal
        view
        virtual
        returns (uint16 index, uint128 correctedPrice)
    {
        if (price < _a || price >= _a + _d * (2**16)) {
            revert Errors.CloberError(Errors.INVALID_PRICE);
        }
        index = uint16((price - _a) / _d);
        if (roundingUp && (price - _a) % _d > 0) {
            unchecked {
                if (index == type(uint16).max) {
                    revert Errors.CloberError(Errors.INVALID_PRICE);
                }
                index += 1;
            }
        }
        correctedPrice = _a + _d * index;
    }
}