// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title AdminControl
 * @notice Base class for non upgradeable contracts to operate admin rights
 * @author AlloyX
 */
abstract contract AdminControl is AccessControl {
  /**
   * @notice Only admin users can perform
   */
  modifier onlyAdmin() {
    require(isAdmin(msg.sender), "Restricted to admins");
    _;
  }

  /**
   * @notice Check if the account is one of the admins
   * @param account The account to check
   */
  function isAdmin(address account) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }

  /**
   * @notice Add the account to admin users
   * @param account The account to add
   */
  function addAdmin(address account) external virtual onlyAdmin {
    grantRole(DEFAULT_ADMIN_ROLE, account);
  }

  /**
   * @notice Renounce admin from the caller
   */
  function renounceAdmin() external virtual {
    renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }
}