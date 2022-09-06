// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @title AccessManager
 * @dev Extend OpenZeppelin AccessControlEnumerable with common shared functionality
 */
contract AccessManager is AccessControlEnumerable {
  /**
   * @dev Validates that the sender is the main admin of the contract or has the required role
   * @param role the role to validate
   */
  modifier onlyAdminOrRole(bytes32 role) {
    _onlyAdminOrRole(role, _msgSender());
    _;
  }

  /**
   * @dev Initializes the main admin role
   * @param admin the address of the main admin role
   */
  constructor(address admin) {
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
  }

  /**
   * @dev Validates that the account is the main admin of the contract or has the required role
   * @param role the role to validate
   * @param account the address to validate
   */
  function _onlyAdminOrRole(bytes32 role, address account) internal view {
    if (!hasRole(DEFAULT_ADMIN_ROLE, account)) {
      _checkRole(role, account);
    }
  }
}