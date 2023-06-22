// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./OmmgOwnable.sol";
import "../interfaces/IOmmgAccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @dev custom role access / ownable
abstract contract OmmgAccessControl is OmmgOwnable, IOmmgAccessControl {
    mapping(bytes32 => RoleData) private _roles;

    /// @dev Reverts if called by any account other than the owner or `role`
    /// @param role The role which is allowed access
    modifier onlyOwnerOrRole(bytes32 role) {
        if (owner() != _msgSender() && !_roles[role].members[_msgSender()])
            revert Unauthorized(_msgSender(), role);
        _;
    }

    /// @dev Reverts if called by any account other than the owner or `role`
    /// @param role The role which is allowed access
    modifier onlyRole(bytes32 role) {
        if (!_roles[role].members[_msgSender()])
            revert Unauthorized(_msgSender(), role);
        _;
    }

    /// @dev Returns `true` if `account` has been granted `role`.
    function hasRole(bytes32 role, address account)
        external
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /// @dev Grants `role` to `account`.
    function grantRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _grantRole(role, account);
    }

    /// @dev Revokes `role` from `account`
    function revokeRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _revokeRole(role, account);
    }

    /// @dev Revokes `role` from the calling account.
    function renounceRole(bytes32 role) public override {
        _revokeRole(role, _msgSender());
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal {
        if (!_roles[role].members[account]) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal {
        if (_roles[role].members[account]) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IOmmgAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}