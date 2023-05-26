// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ZoneInterface {
  event ZoneCreated(bytes32 indexed origin, string name, string symbol);
  event ResourceRegistered(bytes32 indexed parent, string label);

  function getOrigin() external view returns (bytes32);

  function owner() external view returns (address);

  function exists(bytes32 namehash) external view returns (bool);

  function register(
    address to,
    bytes32 parent,
    string memory label
  ) external returns (bytes32 namehash);
}