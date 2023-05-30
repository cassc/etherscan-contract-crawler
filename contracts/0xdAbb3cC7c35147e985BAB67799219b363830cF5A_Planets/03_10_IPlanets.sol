//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

enum PlanetType {
  GAS,
  SOLID
}

struct Settings {
  uint256 seed;
  uint256 planetSize;
  bool hasRings;
  uint256 numMoons;
  PlanetType planetType;
  uint256 hue;
  bool hasWater;
  bytes[7] vars;
}