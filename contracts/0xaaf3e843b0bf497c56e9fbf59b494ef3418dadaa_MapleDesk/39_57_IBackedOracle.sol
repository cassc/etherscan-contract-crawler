// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IBackedOracle
 * @author AlloyX
 */
interface IBackedOracle {
  function latestAnswer() external view returns (int256);

  function decimals() external view returns (uint8);
}