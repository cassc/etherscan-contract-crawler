//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "../libraries/StorageAPI.sol";

abstract contract ACL {
    using StorageAPI for bytes32;

    error NotPermitted();

    modifier isPermitted(bytes32 role) {
        bool permitted = _getPermission(role, msg.sender); // TODO: support GSN/Account abstraction
        if (!permitted) revert NotPermitted();
        _;
    }

    // @notice Gets user permission for a role
    // @param role The bytes32 value of the role
    // @param account The address of the account
    // @return The permission status
    function getPermission(
        bytes32 role,
        address account
    ) external view returns (bool) {
        return _getPermission(role, account);
    }

    // @notice Internal function to get user permission for a role
    // @param role The bytes32 value of the role
    // @param account The address of the account
    // @return The permission status
    function _getPermission(
        bytes32 role,
        address account
    ) internal view returns (bool) {
        bytes32 key = _getKey(role, account);
        return key.getBool();
    }

    // @notice Internal function to get the key for the storage slot
    // @param role The bytes32 value of the role
    // @param account The address of the account
    // @return The bytes32 storage slot
    function _getKey(
        bytes32 role,
        address account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(role, account));
    }
}