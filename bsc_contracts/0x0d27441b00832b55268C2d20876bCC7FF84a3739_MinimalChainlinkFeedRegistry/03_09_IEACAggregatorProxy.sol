// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IEACAggregatorProxy {
    function decimals(address base,address quote) external view
      returns (uint8 precision);
    function latestRoundData() external view 
      returns (
          uint80 roundId,
          int256 answer,
          uint256 startedAt,
          uint256 updatedAt,
          uint80 answeredInRound
      );
}