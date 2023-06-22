// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Version {
  uint32 private immutable _version;

  /// @notice The version of the contract
  /// @return The version ID of this contract implementation
  function contractVersion() external view returns (uint32) {
      return _version;
  }

  constructor(uint32 version) {
    _version = version;
  }
}