// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../libraries/DarkEnergyPackedStruct.sol";

contract OwnableAndAdministrable {
    using DarkEnergyPackedStruct for bytes32;

    error MissingRole(address user, uint256 role);
    error NotOwner(address user);

    event OwnershipTransferred(address indexed user, address indexed newOwner);
    event RoleUpdated(address indexed user, uint256 indexed role, bool indexed status);

    /**
     * @dev There is a maximum of 256 roles: each bit says if the role is on or off
     */
    mapping(address => bytes32) private _addressRoles;

    /**
     * @dev There is one owner
     */
    address internal _owner;

    function _isOwner(address sender) internal view returns(bool) {
        return (sender == _owner || sender == address(this));
    }

    function _hasRole(address sender, uint8 role) internal view returns(bool) {
        bytes32 roles = _addressRoles[sender];
        return roles.getBool(role);
    }

    function _checkOwner(address sender) internal virtual view {
        if (!_isOwner(sender)) {
            revert NotOwner(sender);
        }
    }

    function _checkRoleOrOwner(address sender, uint8 role) internal virtual view {
        if (_isOwner(sender)) return;
        _checkRole(sender, role);
    }

    function _checkRole(address sender, uint8 role) internal virtual view {
        if (sender == address(this)) return;
        bytes32 roles = _addressRoles[sender];
        bool allowed = roles.getBool(role);
        if (!allowed) {
            revert MissingRole(sender, role);
        }
    }

    function _setOwner(address newOwner) internal virtual {
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    function _setRole(address user, uint8 role, bool status) internal virtual {
        _addressRoles[user] = _addressRoles[user].setBit(role, status);
        emit RoleUpdated(user, role, status);
    }

    function setRole(address user, uint8 role, bool status) external virtual {
        _checkOwner(msg.sender);
        _setRole(user, role, status);
    }

    function transferOwnership(address newOwner) external virtual {
        _checkOwner(msg.sender);
        _setOwner(newOwner);
    }

    function owner() external virtual view returns(address) {
        return _owner;
    }
}