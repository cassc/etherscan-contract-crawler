// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.16;

interface IDelegateRegistry {
  function delegation(address delegator, bytes32 id) external view returns (address);
  function setDelegate(bytes32 id, address delegate) external;
  function clearDelegate(bytes32 id) external;
}