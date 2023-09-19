pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IChainlinkPriceFeed {

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

    function latestAnswer() external view returns (int256);
}

contract mockAggregatorV3 is IChainlinkPriceFeed{

    int256 immutable returnValue;

    constructor(int256 currenyValueCents) {
        returnValue = currenyValueCents * 10 ** 10;
    }

    function latestRoundData()
        external
        view
        override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
    {
        return (uint80(0), returnValue, 0, 0, uint80(0));
    }

    function latestAnswer() external view override returns(int256) {
        return returnValue;
    }
}