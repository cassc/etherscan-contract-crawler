// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./Context.sol";

abstract contract BasicAccessControl is Context {
    struct RoleData {
        mapping(address => bool) members;
        uint8 adminRole;
    }

    mapping(uint8 => RoleData) private _roles;

    event RoleAdminChanged (uint8 indexed role, uint8 indexed previousAdminRole, uint8 indexed newAdminRole);
    event RoleGranted (uint8 indexed role, address indexed account, address indexed sender);
    event RoleRevoked (uint8 indexed role, address indexed account, address indexed sender);

    modifier onlyRole(uint8 role) {
        require(hasRole(role, _msgSender()), "Caller has not the needed Role");
        _;
    }

    function hasRole(uint8 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    function getRoleAdmin(uint8 role) public view returns (uint8) {
        return _roles[role].adminRole;
    }

    function grantRole(uint8 role, address account) public virtual onlyRole (getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(uint8 role, address account) public virtual onlyRole (getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    function renounceRole(uint8 role, address account) public virtual {
         require(account == _msgSender(), "Can only renounce roles for self");
        _revokeRole(role, account);
    }

    function _setupRole(uint8 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(uint8 role, uint8 adminRole) internal virtual {
        uint8 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(uint8 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(uint8 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}
