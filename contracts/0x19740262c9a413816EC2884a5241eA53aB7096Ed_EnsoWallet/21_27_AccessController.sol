//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "./ACL.sol";
import "./Roles.sol";

// @notice The OWNER_ROLE must be set in the importing contract's constructor or initialize function
abstract contract AccessController is ACL, Roles {
    using StorageAPI for bytes32;

    event PermissionSet(bytes32 role, address account, bool permission);

    error UnsafeSetting();

    // @notice Sets user permission over a role
    // @param role The bytes32 value of the role
    // @param account The address of the account
    // @param permission The permission status
    function setPermission(
        bytes32 role,
        address account,
        bool permission
    ) external isPermitted(OWNER_ROLE) {
        if (role == OWNER_ROLE && account == msg.sender && permission == false)
            revert UnsafeSetting();
        _setPermission(role, account, permission);
    }

    // @notice Internal function to set user permission over a role
    // @param role The bytes32 value of the role
    // @param account The address of the account
    // @param permission The permission status
    function _setPermission(
        bytes32 role,
        address account,
        bool permission
    ) internal {
        bytes32 key = _getKey(role, account);
        key.setBool(permission);
        emit PermissionSet(role, account, permission);
    }
}