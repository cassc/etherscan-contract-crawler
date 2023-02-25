//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IFastGas {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            uint256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}