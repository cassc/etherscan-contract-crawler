// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title Library for safecasting
/// @author Timeswap Labs
library SafeCast {
  /// @dev Reverts when overflows over uint16.
  error Uint16Overflow();

  /// @dev Reverts when overflows over uint96.
  error Uint96Overflow();

  /// @dev Reverts when overflows over uint160.
  error Uint160Overflow();

  /// @dev Safely cast a uint256 number to uint16.
  /// @dev Reverts when number is greater than uint16.
  /// @param value The uint256 number to be safecasted.
  /// @param result The uint16 result.
  function toUint16(uint256 value) internal pure returns (uint16 result) {
    if (value > type(uint16).max) revert Uint16Overflow();
    result = uint16(value);
  }

  /// @dev Safely cast a uint256 number to uint96.
  /// @dev Reverts when number is greater than uint96.
  /// @param value The uint256 number to be safecasted.
  /// @param result The uint96 result.
  function toUint96(uint256 value) internal pure returns (uint96 result) {
    if (value > type(uint96).max) revert Uint96Overflow();
    result = uint96(value);
  }

  /// @dev Safely cast a uint256 number to uint160.
  /// @dev Reverts when number is greater than uint160.
  /// @param value The uint256 number to be safecasted.
  /// @param result The uint160 result.
  function toUint160(uint256 value) internal pure returns (uint160 result) {
    if (value > type(uint160).max) revert Uint160Overflow();
    result = uint160(value);
  }
}