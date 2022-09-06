// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IChainlinkV3Aggregator {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}