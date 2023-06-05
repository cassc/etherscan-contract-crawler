//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';

/// @title ERC721WithRoles
/// @author Simon Fremaux (@dievardump)
abstract contract ERC721WithRoles {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// @notice emitted when a role is given to a user
    /// @param role the granted role
    /// @param user the user that got a role granted
    event RoleGranted(bytes32 indexed role, address indexed user);

    /// @notice emitted when a role is givrevoked from a user
    /// @param role the revoked role
    /// @param user the user that got a role revoked
    event RoleRevoked(bytes32 indexed role, address indexed user);

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet)
        private _roleMembers;

    /// @notice Helper to know is an address has a role
    /// @param role the role to check
    /// @param user the address to check
    function hasRole(bytes32 role, address user) public view returns (bool) {
        return _roleMembers[role].contains(user);
    }

    /// @notice Helper to list all users in a role
    /// @return list of role members
    function listRole(bytes32 role)
        external
        view
        returns (address[] memory list)
    {
        uint256 count = _roleMembers[role].length();
        list = new address[](count);
        for (uint256 i; i < count; i++) {
            list[i] = _roleMembers[role].at(i);
        }
    }

    /// @notice internal helper to grant a role to a user
    /// @param role role to grant
    /// @param user to grant role to
    function _grantRole(bytes32 role, address user) internal returns (bool) {
        if (_roleMembers[role].add(user)) {
            emit RoleGranted(role, user);
            return true;
        }

        return false;
    }

    /// @notice Helper to revoke a role from a user
    /// @param role role to revoke
    /// @param user to revoke role from
    function _revokeRole(bytes32 role, address user) internal returns (bool) {
        if (_roleMembers[role].remove(user)) {
            emit RoleRevoked(role, user);
            return true;
        }
        return false;
    }
}