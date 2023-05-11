// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

/// @title NativeImmutableState interface
interface INativeImmutableState {
  /// @return Returns the address of Wrapped Native token
  function wrappedNativeToken() external view returns (address);
}