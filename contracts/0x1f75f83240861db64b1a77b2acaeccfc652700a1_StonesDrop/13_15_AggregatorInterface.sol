// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256 answer);
}