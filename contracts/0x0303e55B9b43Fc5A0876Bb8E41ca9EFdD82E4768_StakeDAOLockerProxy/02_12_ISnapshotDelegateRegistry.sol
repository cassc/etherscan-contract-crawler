// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ISnapshotDelegateRegistry {
  function setDelegate(bytes32 id, address delegate) external;
}