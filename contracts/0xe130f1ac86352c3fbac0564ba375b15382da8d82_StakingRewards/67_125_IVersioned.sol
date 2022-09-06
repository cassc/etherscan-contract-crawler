// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

/// @title interface for implementers that have an arbitrary associated tag
interface IVersioned {
  /// @notice Returns the version triplet `[major, minor, patch]`
  function getVersion() external pure returns (uint8[3] memory);
}