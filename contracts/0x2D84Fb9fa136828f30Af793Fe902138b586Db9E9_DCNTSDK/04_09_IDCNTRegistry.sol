// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDCNTRegistry {
  function register(
    address _deployer,
    address _deployment,
    string calldata _key
  ) external;

  function remove(address _deployer, address _deployment) external;

  function query(address _deployer) external returns (address[] memory);
}