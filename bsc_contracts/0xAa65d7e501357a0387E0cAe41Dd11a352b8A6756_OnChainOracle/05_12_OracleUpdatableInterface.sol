// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface OracleUpdatableInterface {
  function transmit(uint64 timestamp_, int192 newPrice_) external;
}