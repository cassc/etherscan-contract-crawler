// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @notice Common events that can be emmitted by multiple contracts
interface IEvents {
  /// @notice Emitted when a safety check fails
  event SafetyCheckTriggered();
}