// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

interface IRoundIdFetcher {
    function getPhaseForTimestamp(address _feed, uint256 _targetTime)
        external
        view
        returns (
            uint80,
            uint256,
            uint80
        );

    function getRoundId(AggregatorV2V3Interface _feed, uint256 _timeStamp)
        external
        view
        returns (uint80 roundId);
}