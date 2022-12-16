// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {Bytes32} from "./../../utils/libraries/Bytes32.sol";

library AccessControlStorage {
    using Bytes32 for bytes32;
    using AccessControlStorage for AccessControlStorage.Layout;

    struct Layout {
        mapping(bytes32 => mapping(address => bool)) roles;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.access.AccessControl.storage")) - 1);

    event RoleGranted(bytes32 role, address account, address operator);
    event RoleRevoked(bytes32 role, address account, address operator);

    /// @notice Grants a role to an account.
    /// @dev Note: Call to this function should be properly access controlled.
    /// @dev Emits a {RoleGranted} event if the account did not previously have the role.
    /// @param role The role to grant.
    /// @param account The account to grant the role to.
    /// @param operator The account requesting the role change.
    function grantRole(Layout storage s, bytes32 role, address account, address operator) internal {
        if (!s.hasRole(role, account)) {
            s.roles[role][account] = true;
            emit RoleGranted(role, account, operator);
        }
    }

    /// @notice Revokes a role from an account.
    /// @dev Note: Call to this function should be properly access controlled.
    /// @dev Emits a {RoleRevoked} event if the account previously had the role.
    /// @param role The role to revoke.
    /// @param account The account to revoke the role from.
    /// @param operator The account requesting the role change.
    function revokeRole(Layout storage s, bytes32 role, address account, address operator) internal {
        if (s.hasRole(role, account)) {
            s.roles[role][account] = false;
            emit RoleRevoked(role, account, operator);
        }
    }

    /// @notice Renounces a role by the sender.
    /// @dev Reverts if `sender` does not have `role`.
    /// @dev Emits a {RoleRevoked} event.
    /// @param sender The message sender.
    /// @param role The role to renounce.
    function renounceRole(Layout storage s, address sender, bytes32 role) internal {
        s.enforceHasRole(role, sender);
        s.roles[role][sender] = false;
        emit RoleRevoked(role, sender, sender);
    }

    /// @notice Retrieves whether an account has a role.
    /// @param role The role.
    /// @param account The account.
    /// @return whether `account` has `role`.
    function hasRole(Layout storage s, bytes32 role, address account) internal view returns (bool) {
        return s.roles[role][account];
    }

    /// @notice Ensures that an account has a role.
    /// @dev Reverts if `account` does not have `role`.
    /// @param role The role.
    /// @param account The account.
    function enforceHasRole(Layout storage s, bytes32 role, address account) internal view {
        if (!s.hasRole(role, account)) {
            revert(string(abi.encodePacked("AccessControl: missing '", role.toASCIIString(), "' role")));
        }
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}