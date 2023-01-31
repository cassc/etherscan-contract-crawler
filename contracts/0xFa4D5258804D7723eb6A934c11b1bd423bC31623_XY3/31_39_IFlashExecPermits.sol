// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;
interface IFlashExecPermits {
  event AddPermit(address indexed target, bytes4 indexed selector);
  event RemovePermit(address indexed target, bytes4 indexed selector);

  function isPermitted(address target, bytes4 selector) external returns (bool);
  function addPermit(address target, bytes4 selector) external;
  function removePermit(address target, bytes4 selector) external;
}