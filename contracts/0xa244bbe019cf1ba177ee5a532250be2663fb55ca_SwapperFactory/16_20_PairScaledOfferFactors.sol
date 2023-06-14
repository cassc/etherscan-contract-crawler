// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {QuotePair, SortedQuotePair} from "splits-utils/LibQuotes.sol";

import {SwapperImpl} from "../SwapperImpl.sol";

/// @title PairScaledOfferFactors Library
/// @author 0xSplits
/// @notice Setters & getters for quote pairs' scaledOfferFactors
library PairScaledOfferFactors {
    /// set pairs' scaled offer factors
    function _set(
        mapping(address => mapping(address => uint32)) storage self,
        SwapperImpl.SetPairScaledOfferFactorParams[] calldata params_
    ) internal {
        uint256 length = params_.length;
        for (uint256 i; i < length;) {
            _set(self, params_[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// set pair's scaled offer factor
    function _set(
        mapping(address => mapping(address => uint32)) storage self,
        SwapperImpl.SetPairScaledOfferFactorParams calldata params_
    ) internal {
        SortedQuotePair memory sqp = params_.quotePair._sort();
        self[sqp.token0][sqp.token1] = params_.scaledOfferFactor;
    }

    /// get pair's scaled offer factor
    function _get(mapping(address => mapping(address => uint32)) storage self, QuotePair calldata quotePair_)
        internal
        view
        returns (uint32)
    {
        return _get(self, quotePair_._sort());
    }

    /// get pair's scaled offer factor
    function _get(mapping(address => mapping(address => uint32)) storage self, SortedQuotePair memory sqp_)
        internal
        view
        returns (uint32)
    {
        return self[sqp_.token0][sqp_.token1];
    }
}