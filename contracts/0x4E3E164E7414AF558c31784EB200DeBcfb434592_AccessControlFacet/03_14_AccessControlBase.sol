// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {AccessControlStorage} from "./../libraries/AccessControlStorage.sol";
import {ContractOwnershipStorage} from "./../libraries/ContractOwnershipStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title Access control via roles management (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC173 (Contract Ownership standard).
abstract contract AccessControlBase is Context {
    using AccessControlStorage for AccessControlStorage.Layout;
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;

    /// @notice Emitted when a role is granted.
    /// @param role the granted role.
    /// @param account the account granted with the role.
    /// @param operator the initiator of the grant.
    event RoleGranted(bytes32 role, address account, address operator);

    /// @notice Emitted when a role is revoked or renounced.
    /// @param role the revoked or renounced role.
    /// @param account the account losing the role.
    /// @param operator the initiator of the revocation, or identical to `account` for a renouncement.
    event RoleRevoked(bytes32 role, address account, address operator);

    /// @notice Grants a role to an account.
    /// @dev Reverts if the sender is not the contract owner.
    /// @dev Emits a {RoleGranted} event if the account did not previously have the role.
    /// @param role The role to grant.
    /// @param account The account to grant the role to.
    function grantRole(bytes32 role, address account) external {
        address operator = _msgSender();
        ContractOwnershipStorage.layout().enforceIsContractOwner(operator);
        AccessControlStorage.layout().grantRole(role, account, operator);
    }

    /// @notice Revokes a role from an account.
    /// @dev Reverts if the sender is not the contract owner.
    /// @dev Emits a {RoleRevoked} event if the account previously had the role.
    /// @param role The role to revoke.
    /// @param account The account to revoke the role from.
    function revokeRole(bytes32 role, address account) external {
        address operator = _msgSender();
        ContractOwnershipStorage.layout().enforceIsContractOwner(operator);
        AccessControlStorage.layout().revokeRole(role, account, operator);
    }

    /// @notice Renounces a role by the sender.
    /// @dev Reverts if the sender does not have `role`.
    /// @dev Emits a {RoleRevoked} event.
    /// @param role The role to renounce.
    function renounceRole(bytes32 role) external {
        AccessControlStorage.layout().renounceRole(_msgSender(), role);
    }

    /// @notice Retrieves whether an account has a role.
    /// @param role The role.
    /// @param account The account.
    /// @return whether `account` has `role`.
    function hasRole(bytes32 role, address account) external view returns (bool) {
        return AccessControlStorage.layout().hasRole(role, account);
    }
}