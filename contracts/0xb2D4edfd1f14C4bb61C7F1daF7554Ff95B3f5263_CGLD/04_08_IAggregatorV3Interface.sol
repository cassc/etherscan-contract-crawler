// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Aggregator Interface
 * @author Splendor Network
 */

interface AggregatorV3Interface {
  /*///////////////////////////////////////////////////////////////
                            METHODS
  //////////////////////////////////////////////////////////////*/

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);
  function getRoundData(uint80 _roundId)
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updateAt, uint80 answeredInRound);
  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updateAt, uint80 answeredInRound);
}