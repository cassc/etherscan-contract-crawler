// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

interface IStorage {
  function getBytes(bytes32 key) external view returns (bytes memory);

  function getBool(bytes32 key) external view returns (bool);

  function getUint(bytes32 key) external view returns (uint256);

  function getInt(bytes32 key) external view returns (int256);

  function getAddress(bytes32 key) external view returns (address);

  function getString(bytes32 key) external view returns (string memory);
}