// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "../structs/Dependency.sol";

interface IVersion {
  function identifier() external pure returns (string memory);
  function version() external pure returns (uint);

  function dependencies() external view returns (Dependency[] memory);
  function updateDependencies(Dependency[] calldata dependencies_) external;

  function deployer() external view returns (address);

  function initialize(bytes calldata data) external;
}