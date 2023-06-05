// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBDelegatesRegistry {
  function deployerOf(address _delegate) external view returns (address _deployer);

  function addDelegate(address _deployer, uint256 _nonce) external;

  function addDelegateCreate2(address _deployer, bytes32 _salt, bytes calldata _bytecode) external;
}