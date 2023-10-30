// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import { ERC721UserRoles } from "../roles/ERC721UserRoles.sol";

error WorldsUserRoles_Sender_Does_Not_Have_Admin_User_Role();
error WorldsUserRoles_Sender_Does_Not_Have_Editor_User_Role();
error WorldsUserRoles_Sender_Is_Not_World_Owner();

/**
 * @title Defines ACLs for individual World NFTs.
 * @author HardlyDifficult & reggieag
 */
abstract contract WorldsUserRoles is ERC721Upgradeable, ERC721UserRoles {
  enum Roles {
    ADMIN,
    EDITOR
    // Additional roles may be added in the future, append only.
  }

  /**
   * @notice Emitted when an admin role is set for a World and a user.
   * @param worldId The ID of the World.
   * @param user The address of the user that is granted an admin role.
   * @dev All existing roles are overwritten.
   */
  event AdminRoleSet(uint256 indexed worldId, address indexed user);

  /**
   * @notice Emitted when an editor role is set for a World and a user.
   * @param worldId The ID of the World.
   * @param user The address of the user that is granted and editor role.
   * @dev All existing roles are overwritten.
   */
  event EditorRoleSet(uint256 indexed worldId, address indexed user);

  ////////////////////////////////////////////////////////////////
  // Owner
  ////////////////////////////////////////////////////////////////

  /// @dev Requires that the caller is the owner of the specified World.
  modifier onlyOwner(uint256 worldId) {
    if (ownerOf(worldId) != _msgSender()) {
      revert WorldsUserRoles_Sender_Is_Not_World_Owner();
    }
    _;
  }

  ////////////////////////////////////////////////////////////////
  // Admin
  ////////////////////////////////////////////////////////////////

  /// @dev Requires that the caller has admin permissions for the specified World.
  modifier onlyAdmin(uint256 worldId) {
    if (!hasAdminRole(worldId, _msgSender())) {
      revert WorldsUserRoles_Sender_Does_Not_Have_Admin_User_Role();
    }
    _;
  }

  /**
   * @notice Sets an admin role for a World and a user.
   * @param worldId The ID of the World.
   * @param user The address of the user that is granted an admin role.
   * @dev Callable by the World owner or admin. Any existing roles for this user are overwritten.
   */
  function setAdminRole(uint256 worldId, address user) public onlyAdmin(worldId) {
    _setUserRole(worldId, user, uint8(Roles.ADMIN));

    emit AdminRoleSet(worldId, user);
  }

  /**
   * @notice Returns true if a user has an admin role granted for a World.
   * @param worldId The ID of the World.
   * @param user The address of the user to check for an admin role.
   * @dev Admin permissions are implicitly granted to the owner.
   */
  function hasAdminRole(uint256 worldId, address user) public view returns (bool hasRole) {
    hasRole = ownerOf(worldId) == user || _hasUserRole(worldId, user, uint8(Roles.ADMIN));
  }

  ////////////////////////////////////////////////////////////////
  // Editor
  ////////////////////////////////////////////////////////////////

  /// @dev Requires that the caller has editor permissions for the specified World.
  modifier onlyEditor(uint256 worldId) {
    if (!hasEditorRole(worldId, _msgSender())) {
      revert WorldsUserRoles_Sender_Does_Not_Have_Editor_User_Role();
    }
    _;
  }

  /**
   * @notice Sets an editor role for a World and a user.
   * @param worldId The ID of the World.
   * @param user The address of the user that is granted an admin role.
   * @dev Callable by the World owner or admin. Any existing roles for this user are overwritten.
   */
  function setEditorRole(uint256 worldId, address user) external onlyAdmin(worldId) {
    _setUserRole(worldId, user, uint8(Roles.EDITOR));

    emit EditorRoleSet(worldId, user);
  }

  /**
   * @notice Returns true if a user has an editor role granted for a World.
   * @param worldId The ID of the World.
   * @param user The address of the user to check for an editor role.
   * @dev Editor permissions are implicitly granted to the owner and admin user roles.
   */
  function hasEditorRole(uint256 worldId, address user) public view returns (bool hasRole) {
    hasRole = hasAdminRole(worldId, user) || _hasUserRole(worldId, user, uint8(Roles.EDITOR));
  }

  ////////////////////////////////////////////////////////////////
  // Removing roles
  ////////////////////////////////////////////////////////////////

  /**
   * @notice Allows the caller to their current role within a World.
   * @param worldId The ID of the World.
   */
  function renounceAllRoles(uint256 worldId) external {
    _revokeAllRolesForUser(worldId, _msgSender());
  }

  /**
   * @notice Revokes all roles for a World and a user.
   * @param worldId The ID of the World.
   * @param user The address of the user whose roles are being revoked.
   * @dev Callable by the World owner or admin.
   */
  function revokeAllRolesForUser(uint256 worldId, address user) external onlyAdmin(worldId) {
    _revokeAllRolesForUser(worldId, user);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new variables without shifting
   * down storage in the inheritance chain. See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev This file uses a total of 800 slots.
   */
  uint256[800] private __gap;
}