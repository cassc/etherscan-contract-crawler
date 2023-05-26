// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

interface ITargetInit {
  function initialize(string calldata _name, string calldata _symbol) external;

  function transferOwnership(address newOwner) external;
}