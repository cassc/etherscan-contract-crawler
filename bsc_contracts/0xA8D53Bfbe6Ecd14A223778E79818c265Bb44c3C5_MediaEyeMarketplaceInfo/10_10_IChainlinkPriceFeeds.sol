// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChainlinkPriceFeeds {

    function convertPrice(
        uint256 _baseAmount,
        uint256 _baseDecimals,
        uint256 _queryDecimals,
        bool _invertedAggregator,
        bool _convertToNative
    ) external view returns (uint256);
}