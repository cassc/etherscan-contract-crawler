// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IAggregatorV3Interface {
    function description() external view returns (string memory);

    function decimals() external view returns (uint8);

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