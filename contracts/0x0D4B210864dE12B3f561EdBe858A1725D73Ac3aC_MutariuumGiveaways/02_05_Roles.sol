// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../libraries/Bits.sol";

contract Roles {
    using Bits for bytes32;

    error MissingRole(address user, uint256 role);

    event RoleUpdated(address indexed user, uint256 indexed role, bool indexed status);

    /**
     * @dev There is a maximum of 256 roles: each bit says if the role is on or off
     */
    mapping(address => bytes32) private _addressRoles;

    function _hasRole(address user, uint8 role) internal view returns(bool) {
        bytes32 roles = _addressRoles[user];
        return roles.getBool(role);
    }

    function _checkRole(address user, uint8 role) internal virtual view {
        if (user == address(this)) return;
        bytes32 roles = _addressRoles[user];
        bool allowed = roles.getBool(role);
        if (!allowed) {
            revert MissingRole(user, role);
        }
    }

    function _setRole(address user, uint8 role, bool status) internal virtual {
        _addressRoles[user] = _addressRoles[user].setBit(role, status);
        emit RoleUpdated(user, role, status);
    }

    function setRole(address user, uint8 role, bool status) external virtual {
        _checkRole(msg.sender, 0);
        _setRole(user, role, status);
    }

    function getRoles(address user) external view returns(bytes32) {
        return _addressRoles[user];
    }
}