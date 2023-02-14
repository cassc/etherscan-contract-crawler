//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**
 * Interface for Chainlink oracle feeds
 */
interface IPriceFeed {
    function latestRoundData() external view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
    function decimals() external view returns (uint8);
}