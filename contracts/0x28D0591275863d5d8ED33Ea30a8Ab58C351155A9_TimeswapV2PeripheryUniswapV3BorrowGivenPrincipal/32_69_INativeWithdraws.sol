// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title NativeWithdraws interface

interface INativeWithdraws {
  /// @notice Unwraps the contract's Wrapped Native token balance and sends it to recipient as Native token.
  /// @dev The amountMinimum parameter prevents malicious contracts from stealing Wrapped Native from users.
  /// @param amountMinimum The minimum amount of Wrapped Native to unwrap
  /// @param recipient The address receiving Native token
  function unwrapWrappedNatives(uint256 amountMinimum, address recipient) external payable;
}