// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "../OrderBook.sol";
import "./ArithmeticPriceBook.sol";

contract StableMarket is OrderBook, ArithmeticPriceBook {
    constructor(
        address orderToken_,
        address quoteToken_,
        address baseToken_,
        uint96 quoteUnit_,
        int24 makerFee_,
        uint24 takerFee_,
        address factory_,
        uint128 a_,
        uint128 d_
    )
        OrderBook(orderToken_, quoteToken_, baseToken_, quoteUnit_, makerFee_, takerFee_, factory_)
        ArithmeticPriceBook(a_, d_)
    {}

    function indexToPrice(uint16 priceIndex) public view override returns (uint128) {
        return _indexToPrice(priceIndex);
    }
}