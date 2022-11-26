// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../interfaces/RegistryAccessErrors.sol";

abstract contract RegistryAccess is AccessControlUpgradeable, RegistryAccessErrors {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant RESTORER_ROLE = keccak256("RESTORER_ROLE");
  bytes32 public constant ACCEPTER_ROLE = keccak256("ACCEPTER_ROLE");

  function __RegistryAccess_init(address admin) internal onlyInitializing {
    if (admin == address(0)) {
      revert InvalidAdminAddress();
    }
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _setupRole(MINTER_ROLE, admin);
    _setupRole(RESTORER_ROLE, admin);
    _setupRole(ACCEPTER_ROLE, admin);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function setRoleAdmin(bytes32 role, bytes32 adminRole) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
    _setRoleAdmin(role, adminRole);
  }
}