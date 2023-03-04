// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "../structs/EnumerableMap.sol";
import "./ISafeAccessControlEnumerable.sol";
import "./SafeOwnable.sol";

/**
 * @title Safe Access Control Enumerable
 * @author 0x0Louis
 * @notice This contract is used to manage a set of addresses that have been granted a specific role.
 * Only the owner can be granted the DEFAULT_ADMIN_ROLE.
 */
abstract contract SafeAccessControlEnumerable is SafeOwnable, ISafeAccessControlEnumerable {
    using EnumerableMap for EnumerableMap.AddressSet;

    struct EnumerableRoleData {
        EnumerableMap.AddressSet members;
        bytes32 adminRole;
    }

    bytes32 public constant override DEFAULT_ADMIN_ROLE = 0x00;

    mapping(bytes32 => EnumerableRoleData) private _roles;

    /**
     * @dev Modifier that checks if the caller has the role `role`.
     */
    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, msg.sender)) revert SafeAccessControlEnumerable__OnlyRole(msg.sender, role);
        _;
    }

    /**
     * @dev Modifier that checks if the caller has the role `role` or the role `DEFAULT_ADMIN_ROLE`.
     */
    modifier onlyOwnerOrRole(bytes32 role) {
        if (owner() != msg.sender && !hasRole(role, msg.sender)) {
            revert SafeAccessControlEnumerable__OnlyOwnerOrRole(msg.sender, role);
        }
        _;
    }

    /**
     * @notice Checks if an account has a role.
     * @param role The role to check.
     * @param account The account to check.
     * @return True if the account has the role, false otherwise.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @notice Returns the number of accounts that have the role.
     * @param role The role to check.
     * @return The number of accounts that have the role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @notice Returns the account at the given index in the role.
     * @param role The role to check.
     * @param index The index to check.
     * @return The account at the given index in the role.
     */
    function getRoleMemberAt(bytes32 role, uint256 index) public view override returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @notice Returns the admin role of the given role.
     * @param role The role to check.
     * @return The admin role of the given role.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @notice Grants `role` to `account`.
     * @param role The role to grant.
     * @param account The account to grant the role to.
     */
    function grantRole(bytes32 role, address account) public override onlyOwnerOrRole((getRoleAdmin(role))) {
        if (!_grantRole(role, account)) revert SafeAccessControlEnumerable__AccountAlreadyHasRole(account, role);
    }

    /**
     * @notice Revokes `role` from `account`.
     * @param role The role to revoke.
     * @param account The account to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public override onlyOwnerOrRole((getRoleAdmin(role))) {
        if (!_revokeRole(role, account)) revert SafeAccessControlEnumerable__AccountDoesNotHaveRole(account, role);
    }

    /**
     * @notice Revokes `role` from the calling account.
     * @param role The role to revoke.
     */
    function renounceRole(bytes32 role) public override {
        if (!_revokeRole(role, msg.sender)) {
            revert SafeAccessControlEnumerable__AccountDoesNotHaveRole(msg.sender, role);
        }
    }

    function _transferOwnership(address newOwner) internal override {
        address previousOwner = owner();
        super._transferOwnership(newOwner);

        _revokeRole(DEFAULT_ADMIN_ROLE, previousOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
    }

    /**
     * @notice Grants `role` to `account`.
     * @param role The role to grant.
     * @param account The account to grant the role to.
     * @return True if the role was granted to the account, that is if the account did not already have the role,
     * false otherwise.
     */
    function _grantRole(bytes32 role, address account) internal returns (bool) {
        if (role == DEFAULT_ADMIN_ROLE && owner() != account || !_roles[role].members.add(account)) return false;

        emit RoleGranted(msg.sender, role, account);
        return true;
    }

    /**
     * @notice Revokes `role` from `account`.
     * @param role The role to revoke.
     * @param account The account to revoke the role from.
     * @return True if the role was revoked from the account, that is if the account had the role,
     * false otherwise.
     */
    function _revokeRole(bytes32 role, address account) internal returns (bool) {
        if (role == DEFAULT_ADMIN_ROLE && owner() != account || !_roles[role].members.remove(account)) return false;

        emit RoleRevoked(msg.sender, role, account);
        return true;
    }

    /**
     * @notice Sets `role` as the admin role of `adminRole`.
     * @param role The role to set as the admin role.
     * @param adminRole The role to set as the admin role of `role`.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        _roles[role].adminRole = adminRole;

        emit RoleAdminSet(msg.sender, role, adminRole);
    }
}