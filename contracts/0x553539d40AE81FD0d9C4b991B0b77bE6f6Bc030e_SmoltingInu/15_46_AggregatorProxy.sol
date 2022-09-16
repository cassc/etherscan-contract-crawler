// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol';

/**
 * @dev Interface for chainlink feed proxy, that contains info
 * about all aggregators for data feed
 */

interface AggregatorProxy is AggregatorV2V3Interface {
  function aggregator() external view returns (address);

  function phaseId() external view returns (uint16);
}