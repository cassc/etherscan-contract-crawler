// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./AccessControlledOffchainAggregator.sol";

contract AccessControlTestHelper {

  event Dummy(); // Used to silence warning that these methods are pure

  function readGetRoundData(address _aggregator, uint80 _roundID)
    external
  {
    AccessControlledOffchainAggregator(_aggregator).getRoundData(_roundID);
    emit Dummy();
  }

  function readLatestRoundData(address _aggregator)
    external
  {
    AccessControlledOffchainAggregator(_aggregator).latestRoundData();
    emit Dummy();
  }

  function readLatestAnswer(address _aggregator)
    external
  {
    AccessControlledOffchainAggregator(_aggregator).latestAnswer();
    emit Dummy();
  }

  function readLatestTimestamp(address _aggregator)
    external
  {
    AccessControlledOffchainAggregator(_aggregator).latestTimestamp();
    emit Dummy();
  }

  function readLatestRound(address _aggregator)
    external
  {
    AccessControlledOffchainAggregator(_aggregator).latestRound();
    emit Dummy();
  }

  function readGetAnswer(address _aggregator, uint256 _roundID)
    external
  {
    AccessControlledOffchainAggregator(_aggregator).getAnswer(_roundID);
    emit Dummy();
  }

  function readGetTimestamp(address _aggregator, uint256 _roundID)
    external
  {
    AccessControlledOffchainAggregator(_aggregator).getTimestamp(_roundID);
    emit Dummy();
  }

  function testLatestTransmissionDetails(address _aggregator) external view {
      OffchainAggregator(_aggregator).latestTransmissionDetails();
  }
}