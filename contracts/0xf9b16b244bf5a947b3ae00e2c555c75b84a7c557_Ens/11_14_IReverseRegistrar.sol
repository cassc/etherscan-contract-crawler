// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.19;

interface IReverseRegistrar {
  function setName(string memory name) external returns (bytes32);
}