// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICLSynchronicityPriceAdapter {
  /**
   * @notice Calculates the current answer based on the aggregators.
   * @return int256 latestAnswer
   */
  function latestAnswer() external view returns (int256);

  /**
   * @notice Returns the name identifier of the feed
   * @return string name
   */
  function name() external view returns (string memory);

  error DecimalsAboveLimit();
  error DecimalsNotEqual();
}