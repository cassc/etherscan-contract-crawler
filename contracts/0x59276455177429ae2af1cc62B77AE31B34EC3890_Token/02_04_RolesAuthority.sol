// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Auth} from "./Auth.sol";

/// @notice Role based Authority that supports up to 256 roles, target is always this.
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/authorities/RolesAuthority.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-roles/blob/master/src/roles.sol)
contract RolesAuthority is Auth {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);

    event PublicCapabilityUpdated(bytes4 indexed functionSig, bool enabled);

    event RoleCapabilityUpdated(uint8 indexed role, bytes4 indexed functionSig, bool enabled);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) Auth(_owner) {}

    /*//////////////////////////////////////////////////////////////
                            ROLE/USER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => bytes32) public getUserRoles;

    mapping(bytes4 => bool) public isCapabilityPublic;

    mapping(bytes4 => bytes32) public getRolesWithCapability;

    function doesUserHaveRole(address user, uint8 role) public view virtual returns (bool) {
        return (uint256(getUserRoles[user]) >> role) & 1 != 0;
    }

    function doesRoleHaveCapability(
        uint8 role,
        bytes4 functionSig
    ) external view virtual returns (bool) {
        return (uint256(getRolesWithCapability[functionSig]) >> role) & 1 != 0;
    }

    /*//////////////////////////////////////////////////////////////
                           AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function canCall(
        address user,
        bytes4 functionSig
    ) public view virtual override returns (bool) {
        return
            isCapabilityPublic[functionSig] ||
            bytes32(0) != getUserRoles[user] & getRolesWithCapability[functionSig];
    }

    /*//////////////////////////////////////////////////////////////
                   ROLE CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setPublicCapability(
        bytes4 functionSig,
        bool enabled
    ) external virtual requiresAuth {
        isCapabilityPublic[functionSig] = enabled;

        emit PublicCapabilityUpdated(functionSig, enabled);
    }

    function setRoleCapability(
        uint8 role,
        bytes4 functionSig,
        bool enabled
    ) external virtual requiresAuth {
        if (enabled) {
            getRolesWithCapability[functionSig] |= bytes32(1 << role);
        } else {
            getRolesWithCapability[functionSig] &= ~bytes32(1 << role);
        }

        emit RoleCapabilityUpdated(role, functionSig, enabled);
    }

    /*//////////////////////////////////////////////////////////////
                       USER ROLE ASSIGNMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function setUserRole(
        address user,
        uint8 role,
        bool enabled
    ) external virtual requiresAuth {
        if (enabled) {
            getUserRoles[user] |= bytes32(1 << role);
        } else {
            getUserRoles[user] &= ~bytes32(1 << role);
        }

        emit UserRoleUpdated(user, role, enabled);
    }
}