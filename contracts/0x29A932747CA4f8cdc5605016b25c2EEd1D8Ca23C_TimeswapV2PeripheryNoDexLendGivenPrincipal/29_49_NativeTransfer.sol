// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

library NativeTransfer {
  error NativeTransferFailed(address to, uint256 value);

  /// @notice Transfers Natives to the recipient address
  /// @dev Reverts if the transfer fails
  /// @param to The destination of the transfer
  /// @param value The value to be transferred
  function safeTransferNatives(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    if (!success) {
      revert NativeTransferFailed(to, value);
    }
  }
}