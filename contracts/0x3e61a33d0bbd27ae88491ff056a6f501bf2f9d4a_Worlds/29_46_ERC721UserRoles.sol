// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

error ERC721UserRoles_User_Has_No_Roles();
error ERC721UserRoles_User_Must_Not_Be_Zero_Address();
error ERC721UserRoles_User_Role_Already_Set();

/**
 * @title Defines storage and access of users roles for individual ERC721 tokens.
 * @author reggieag & HardlyDifficult
 */
abstract contract ERC721UserRoles {
  /// @notice Stores user roles per-token as a bitfield. Consumers should define the significance of each bit,
  /// referenced as `role` below.
  mapping(uint256 tokenId => mapping(uint256 nonce => mapping(address user => bytes32 roles)))
    private $tokenIdToNonceToUserToRoles;

  /// @notice The nonce to use for every access to `$tokenIdToNonceToUserToRoles`.
  /// @dev This structures storage to allow a user controlled `nonce` in the future, enabling delete all.
  uint256 private constant DEFAULT_NONCE = 0;

  /**
   * @notice Emitted when all token roles for a user are revoked.
   * @param tokenId The token for which this user had their roles revoked.
   * @param user The address of the user who had their roles revoked.
   */
  event UserRolesRevoked(uint256 indexed tokenId, address indexed user);

  /**
   * @notice Sets a user role for a given token. Overwrites any existing roles.
   * @dev No events are emitted, the caller should emit if required allowing for user friendly naming.
   */
  function _setUserRole(uint256 tokenId, address user, uint8 role) internal {
    if (_hasUserRole(tokenId, user, role)) {
      revert ERC721UserRoles_User_Role_Already_Set();
    }

    $tokenIdToNonceToUserToRoles[tokenId][DEFAULT_NONCE][user] = bytes32(1 << role);
  }

  function _hasUserRole(uint256 tokenId, address user, uint8 role) internal view returns (bool userHasRole) {
    userHasRole = (uint256($tokenIdToNonceToUserToRoles[tokenId][DEFAULT_NONCE][user]) >> role) & 1 != 0;
  }

  /// @notice Revokes all roles for a user on a given token.
  function _revokeAllRolesForUser(uint256 tokenId, address user) internal {
    if ($tokenIdToNonceToUserToRoles[tokenId][DEFAULT_NONCE][user] == 0) {
      revert ERC721UserRoles_User_Has_No_Roles();
    }

    delete $tokenIdToNonceToUserToRoles[tokenId][DEFAULT_NONCE][user];

    emit UserRolesRevoked(tokenId, user);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new variables without shifting
   * down storage in the inheritance chain. See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev This file uses a total of 200 slots.
   */
  uint256[199] private __gap;
}