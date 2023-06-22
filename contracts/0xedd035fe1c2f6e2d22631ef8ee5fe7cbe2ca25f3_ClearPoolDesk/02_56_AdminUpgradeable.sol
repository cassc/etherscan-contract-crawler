// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title AdminUpgradeable
 * @notice Base class for all the contracts which need convenience methods to operate admin rights
 * @author AlloyX
 */
abstract contract AdminUpgradeable is AccessControlUpgradeable {
  function __AdminUpgradeable_init(address deployer) internal onlyInitializing {
    __AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, deployer);
  }

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
}