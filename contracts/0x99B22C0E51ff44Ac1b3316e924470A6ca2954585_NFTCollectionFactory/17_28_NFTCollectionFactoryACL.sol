// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../../interfaces/internal/roles/IRoles.sol";

error NFTCollectionFactoryACL_Caller_Must_Have_Admin_Role();
error NFTCollectionFactoryACL_Constructor_RolesContract_Is_Not_A_Contract();

/**
 * @title ACL definitions for the factory.
 */
abstract contract NFTCollectionFactoryACL is Context {
  using AddressUpgradeable for address;

  IRoles private immutable _rolesManager;

  modifier onlyAdmin() {
    if (!_rolesManager.isAdmin(_msgSender())) {
      revert NFTCollectionFactoryACL_Caller_Must_Have_Admin_Role();
    }
    _;
  }

  /**
   * @notice Defines requirements for the collection drop factory at deployment time.
   * @param rolesManager_ The address of the contract defining roles for collections to use.
   */
  constructor(address rolesManager_) {
    if (!rolesManager_.isContract()) {
      revert NFTCollectionFactoryACL_Constructor_RolesContract_Is_Not_A_Contract();
    }

    _rolesManager = IRoles(rolesManager_);
  }

  /**
   * @notice The contract address which manages common roles.
   * @dev Defines a centralized admin role definition for permissioned functions below.
   * @return managerContract The contract address with role definitions.
   */
  function rolesManager() external view returns (address managerContract) {
    managerContract = address(_rolesManager);
  }

  // This mixin consumes 0 slots.
}