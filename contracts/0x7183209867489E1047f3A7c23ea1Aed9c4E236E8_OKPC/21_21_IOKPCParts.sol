//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

interface IOKPCParts {
  // errors
  error IndexOutOfBounds(uint256 index, uint256 maxIndex);

  // structures
  struct Color {
    bytes6 light;
    bytes6 regular;
    bytes6 dark;
    string name;
  }

  struct Vector {
    string data;
    string name;
  }

  // functions
  function getColor(uint256 index) external view returns (Color memory);

  function getHeadband(uint256 index) external view returns (Vector memory);

  function getSpeaker(uint256 index) external view returns (Vector memory);

  function getWord(uint256 index) external view returns (string memory);
}