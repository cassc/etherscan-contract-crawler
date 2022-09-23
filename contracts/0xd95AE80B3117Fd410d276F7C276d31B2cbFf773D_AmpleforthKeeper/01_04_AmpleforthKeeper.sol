// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {LastUpdater} from "../LastUpdater.sol";

/**
 * @dev Ampleforth oracle contract interface
 */
interface AmpleforthInterface {
  function pushReport(uint256 payload) external;

  function purgeReports() external;

  function addProvider(address) external;

  event ProviderReportPushed(address indexed provider, uint256 payload, uint256 timestamp);
}

/**
 * @title Ampleforth Keeper
 * @notice This is a Chainlink Keeper-compatible contract that records every time the feed answer changes,
 *  and pushes the answer to the Ampleforth oracle contract.
 */
contract AmpleforthKeeper is LastUpdater {
  AmpleforthInterface public immutable ampleforthOracle;

  /**
   * @param feedContractAddress Address of Chainlink feed to read from
   * @param ampleforthOracleAddress Address of Ampleforth oracle to push reports to
   */
  constructor(address feedContractAddress, address ampleforthOracleAddress) LastUpdater(feedContractAddress) {
    ampleforthOracle = AmpleforthInterface(ampleforthOracleAddress);
  }

  /**
   * @notice Push a report to the Ampleforth Oracle contract with the latest answer.
   */
  function performUpkeep(bytes calldata) external override {
    (bool hasNewAnswer, int256 latestAnswer) = super.updateAnswer();

    require(hasNewAnswer, "Feed has not changed");
    require(latestAnswer >= 0, "Invalid feed answer");
    ampleforthOracle.pushReport(uint256(latestAnswer));
  }
}