// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Strings.sol";

library Colors {
  using Strings for uint256;

  struct Color {
    uint256 hue;
    uint256 saturation;
    uint256 lightness;
  }

  function fromSeedWithMinMax(string memory seed, uint256 hMin, uint256 hMax, uint256 sMin, uint256 sMax, uint256 lMin, uint256 lMax) public pure returns (Color memory) {
    return
      Color(
        valueFromSeed(string(abi.encodePacked("H", seed)), hMin, hMax),
        valueFromSeed(string(abi.encodePacked("S", seed)), sMin, sMax),
        valueFromSeed(string(abi.encodePacked("L", seed)), lMin, lMax)
      );
  }

  function toHSLString(Color memory color) public pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          "hsl(",
          color.hue.toString(),
          ",",
          color.saturation.toString(),
          "%,",
          color.lightness.toString(),
          "%)"
        )
      );
  }

  function valueFromSeed(string memory seed, uint256 from, uint256 to) public pure returns (uint256) {
    if (to <= from) return from;
    return (uint256(keccak256(abi.encodePacked(seed))) % (to - from)) + from;
  }
}