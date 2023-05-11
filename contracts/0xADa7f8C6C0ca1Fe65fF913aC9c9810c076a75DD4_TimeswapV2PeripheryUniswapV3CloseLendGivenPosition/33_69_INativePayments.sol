// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title NativePayments interface
/// @notice Functions to ease payments of native tokens
interface INativePayments {
  /// @notice Refunds any Native Token balance held by this contract to the `msg.sender`
  function refundNatives() external payable;
}