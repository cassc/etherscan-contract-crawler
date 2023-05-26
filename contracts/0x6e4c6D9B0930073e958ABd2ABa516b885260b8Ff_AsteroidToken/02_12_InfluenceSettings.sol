// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;


library InfluenceSettings {

  // Game constants
  bytes32 public constant MASTER_SEED = "influence";
  uint32 public constant MAX_RADIUS = 375142; // in meters
  uint32 public constant START_TIMESTAMP = 1609459200; // Zero date timestamp for orbits
  uint public constant TOTAL_ASTEROIDS = 250000;
}