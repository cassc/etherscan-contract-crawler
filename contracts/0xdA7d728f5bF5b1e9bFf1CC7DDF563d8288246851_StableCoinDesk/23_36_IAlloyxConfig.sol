// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAlloyxConfig {
  function getNumber(uint256 index) external returns (uint256);

  function getAddress(uint256 index) external returns (address);

  function getBoolean(uint256 index) external returns (bool);

  function setAddress(uint256 index, address newAddress) external;

  function setNumber(uint256 index, uint256 newNumber) external;

  function setBoolean(uint256 booleanIndex, bool newBoolean) external;
}