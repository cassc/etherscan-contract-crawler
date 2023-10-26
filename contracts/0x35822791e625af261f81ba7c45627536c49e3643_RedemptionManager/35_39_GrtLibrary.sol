// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/// @title A title that should describe the contract/interface
/// @author Developed by Labrys on behalf of GRT Wines
/// @custom:contributor mfbevan (mfbevan.eth)
/// @notice Helpers for GRT Wines contracts
library GrtLibrary {
  /// @dev Thrown whenever a zero-address check fails
  /// @param field The name of the field on which the zero-address check failed
  error ZeroAddress(bytes32 field);

  /// @notice Check if a field is the zero address, if so revert with the field name
  /// @param _address The address to check
  /// @param _field The name of the field to check
  function checkZeroAddress(address _address, bytes32 _field) internal pure {
    if (_address == address(0)) {
      revert ZeroAddress(_field);
    }
  }
}