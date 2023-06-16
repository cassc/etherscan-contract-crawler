// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '../interfaces/IRoleControl.sol';
import { IERC2981 } from '@openzeppelin/contracts/interfaces/IERC2981.sol';

/// @notice Below serve as the baseline to demonstrate the desing, additional function are needed
/// @dev RoleControl is a custom contract built on AccessControlUpgradeable
abstract contract RoleControl is AccessControlUpgradeable, IRoleControl {
    modifier hasAdminRole() {
        require(isAdmin(_msgSender()), 'RoleControl: Not an admin');
        _;
    }

    /// @notice Return if a address has admin role
    /// @param account The address to verify
    /// @return True if the address has admin role
    function isAdmin(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @notice Give Admin Role to the given address.
    /// @param account The address to give the Admin Role.
    /// @dev The call must originate from an admin.
    function addAdmin(address account) public hasAdminRole {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @notice Revoke Admin Role from the given address.
    /// @param account The address to revoke the Admin Role.
    /// @dev The call must originate from an admin.
    function removeAdmin(address account) public hasAdminRole {
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == 0x49064906 || // ERC-4906
            super.supportsInterface(interfaceId);
    }
}