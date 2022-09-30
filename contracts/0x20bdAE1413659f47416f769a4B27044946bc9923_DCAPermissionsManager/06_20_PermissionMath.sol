// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '../interfaces/IDCAPermissionManager.sol';

/// @title Permission Math library
/// @notice Provides functions to easily convert from permissions to an int representation and viceversa
library PermissionMath {
  /// @notice Takes a list of permissions and returns the int representation of the set that contains them all
  /// @param _permissions The list of permissions
  /// @return _representation The uint representation
  function toUInt8(IDCAPermissionManager.Permission[] memory _permissions) internal pure returns (uint8 _representation) {
    for (uint256 i = 0; i < _permissions.length; ) {
      _representation |= uint8(1 << uint8(_permissions[i]));
      unchecked {
        i++;
      }
    }
  }

  /// @notice Takes an int representation of a set of permissions, and returns whether it contains the given permission
  /// @param _representation The int representation
  /// @param _permission The permission to check for
  /// @return _hasPermission Whether the representation contains the given permission
  function hasPermission(uint8 _representation, IDCAPermissionManager.Permission _permission) internal pure returns (bool _hasPermission) {
    uint256 _bitMask = 1 << uint8(_permission);
    _hasPermission = (_representation & _bitMask) != 0;
  }
}