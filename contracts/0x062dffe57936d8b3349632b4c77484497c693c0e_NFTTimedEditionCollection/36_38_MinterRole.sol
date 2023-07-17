// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./AdminRole.sol";

error MinterRole_Caller_Does_Not_Have_Minter_Or_Admin_Role();

/**
 * @title Defines a role for minter accounts.
 * @dev Wraps a role from OpenZeppelin's AccessControl for easy integration.
 * @author batu-inal & HardlyDifficult
 */
abstract contract MinterRole is AccessControlUpgradeable, AdminRole {
  /**
   * @notice The `role` type used for approve minters.
   * @return `keccak256("MINTER_ROLE")`
   */
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  /**
   * @notice Ensures that the sender has permissions to mint.
   * @dev Restrictions may be extended in derived contracts via overriding `_requireCanMint`.
   */
  modifier hasPermissionToMint() {
    _requireCanMint();
    _;
  }

  function _initializeMinterRole(address minter) internal {
    // Grant the role to a specified account
    _grantRole(MINTER_ROLE, minter);
  }

  /**
   * @notice Adds an account as an approved minter.
   * @dev Only callable by admins, as enforced by `grantRole`.
   * @param account The address to be approved.
   */
  function grantMinter(address account) external {
    grantRole(MINTER_ROLE, account);
  }

  /**
   * @notice Removes an account from the set of approved minters.
   * @dev Only callable by admins, as enforced by `revokeRole`.
   * @param account The address to be removed.
   */
  function revokeMinter(address account) external {
    revokeRole(MINTER_ROLE, account);
  }

  /**
   * @notice Checks if the account provided is an minter.
   * @param account The address to check.
   * @return approved True if the account is an minter.
   */
  function isMinter(address account) public view returns (bool approved) {
    approved = hasRole(MINTER_ROLE, account);
  }

  /**
   * @notice Reverts if the current msg.sender is not approved to mint from this contract.
   * @dev This virtual function allows other mixins to add additional restrictions on minting.
   */
  function _requireCanMint() internal view virtual {
    if (!isMinter(msg.sender) && !isAdmin(msg.sender)) {
      revert MinterRole_Caller_Does_Not_Have_Minter_Or_Admin_Role();
    }
  }
}