// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

using {_sort} for ConvertedQuotePair global;

struct ConvertedQuotePair {
    address cBase;
    address cQuote;
}

struct SortedConvertedQuotePair {
    address cToken0;
    address cToken1;
}

function _sort(ConvertedQuotePair memory cqp) pure returns (SortedConvertedQuotePair memory) {
    return (cqp.cBase > cqp.cQuote)
        ? SortedConvertedQuotePair({cToken0: cqp.cQuote, cToken1: cqp.cBase})
        : SortedConvertedQuotePair({cToken0: cqp.cBase, cToken1: cqp.cQuote});
}