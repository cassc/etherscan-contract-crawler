// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

/// @title IPeriodMapper
/// @notice A mapping of timestamps to "periods"
interface IPeriodMapper {
  /// @notice Returns the period that a timestamp resides in
  function periodOf(uint256 timestamp) external pure returns (uint256 period);

  /// @notice Returns the starting timestamp of a given period
  function startOf(uint256 period) external pure returns (uint256 timestamp);
}