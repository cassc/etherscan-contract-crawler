// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {ConvertedQuotePair, SortedConvertedQuotePair} from "./ConvertedQuotePair.sol";

using {_sort, _convert, _convertAndSort} for QuotePair global;

struct QuoteParams {
    QuotePair quotePair;
    uint128 baseAmount;
    bytes data;
}

struct QuotePair {
    address base;
    address quote;
}

struct SortedQuotePair {
    address token0;
    address token1;
}

function _sort(QuotePair memory qp) pure returns (SortedQuotePair memory) {
    return (qp.base > qp.quote)
        ? SortedQuotePair({token0: qp.quote, token1: qp.base})
        : SortedQuotePair({token0: qp.base, token1: qp.quote});
}

function _convert(QuotePair calldata qp, function (address) internal view returns (address) convert)
    view
    returns (ConvertedQuotePair memory)
{
    return ConvertedQuotePair({cBase: convert(qp.base), cQuote: convert(qp.quote)});
}

function _convertAndSort(QuotePair calldata qp, function (address) internal view returns (address) convert)
    view
    returns (SortedConvertedQuotePair memory)
{
    return _convert(qp, convert)._sort();
}