// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../access/ownable/OwnableInternal.sol";

import "./AccessControlInternal.sol";
import "./IAccessControlAdmin.sol";

/**
 * @title Roles - Admin
 * @notice Allows you to initiate access controls as current contract owner by giving DEFAULT_ADMIN_ROLE to an address.
 *
 * @custom:type eip-2535-facet
 * @custom:category Access
 * @custom:peer-dependencies IAccessControl
 * @custom:provides-interfaces IAccessControlAdmin
 */
contract AccessControlAdmin is IAccessControlAdmin, OwnableInternal, AccessControlInternal {
    function grantAdminRole(address admin) external override onlyOwner {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }
}