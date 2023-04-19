// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { Owned } from "../utils/Owned.sol";
import { Permission } from "../interfaces/vault/IPermissionRegistry.sol";

/**
 * @title   PermissionRegistry
 * @author  RedVeil
 * @notice  Allows the DAO to endorse and reject addresses for security purposes.
 */
contract PermissionRegistry is Owned {
  /*//////////////////////////////////////////////////////////////
                            IMMUTABLES
    //////////////////////////////////////////////////////////////*/

  /// @param _owner `AdminProxy`
  constructor(address _owner) Owned(_owner) {}

  /*//////////////////////////////////////////////////////////////
                          PERMISSIONS
    //////////////////////////////////////////////////////////////*/

  mapping(address => Permission) public permissions;

  event PermissionSet(address target, bool newEndorsement, bool newRejection);

  error Mismatch();

  /**
   * @notice Set permissions for an array of target. Caller must be owner. (`VaultController` via `AdminProxy`)
   * @param targets `AdminProxy`
   * @param newPermissions An array of permissions to set for the targets.
   * @dev A permission can never be both endorsed and rejected.
   */
  function setPermissions(address[] calldata targets, Permission[] calldata newPermissions) external onlyOwner {
    uint256 len = targets.length;
    if (len != newPermissions.length) revert Mismatch();

    for (uint256 i = 0; i < len; i++) {
      if (newPermissions[i].endorsed && newPermissions[i].rejected) revert Mismatch();

      emit PermissionSet(targets[i], newPermissions[i].endorsed, newPermissions[i].rejected);

      permissions[targets[i]] = newPermissions[i];
    }
  }

  function endorsed(address target) external view returns (bool) {
    return permissions[target].endorsed;
  }

  function rejected(address target) external view returns (bool) {
    return permissions[target].rejected;
  }
}