// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

interface IRandomizer {
  function random(uint256 seed) external view returns (uint256);
}