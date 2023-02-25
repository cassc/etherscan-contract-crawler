// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {FirmBase, IMPL_INIT_NOOP_SAFE, IMPL_INIT_NOOP_ADDR} from "../bases/FirmBase.sol";
import {ISafe} from "../bases/SafeAware.sol";

import {
    IRoles,
    ROOT_ROLE_ID,
    ROLE_MANAGER_ROLE_ID,
    ONLY_ROOT_ROLE_AS_ADMIN,
    NO_ROLE_ADMINS,
    SAFE_OWNER_ROLE_ID
} from "./interfaces/IRoles.sol";

/**
 * @title Roles
 * @author Firm ([email protected])
 * @notice Role management module supporting up to 256 roles optimized for batched actions
 * Inspired by Solmate's RolesAuthority and OpenZeppelin's AccessControl
 * https://github.com/Rari-Capital/solmate/blob/main/src/auth/authorities/RolesAuthority.sol)
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol
 */
contract Roles is FirmBase, IRoles {
    string public constant moduleId = "org.firm.roles";
    uint256 public constant moduleVersion = 1;

    mapping(address => bytes32) public getUserRoles;
    mapping(uint8 => bytes32) public getRoleAdmins;
    uint256 public roleCount;

    event RoleCreated(uint8 indexed roleId, bytes32 roleAdmins, string name, address indexed actor);
    event RoleNameChanged(uint8 indexed roleId, string name, address indexed actor);
    event RoleAdminsSet(uint8 indexed roleId, bytes32 roleAdmins, address indexed actor);
    event UserRolesChanged(address indexed user, bytes32 oldUserRoles, bytes32 newUserRoles, address indexed actor);

    error UnauthorizedNoRole(uint8 requiredRole);
    error UnauthorizedNotAdmin(uint8 roleId);
    error UnexistentRole(uint8 roleId);
    error RoleLimitReached();
    error InvalidRoleAdmins();

    bytes32 internal constant SAFE_OWNER_ROLE_MASK = ~bytes32(uint256(1) << SAFE_OWNER_ROLE_ID);

    ////////////////////////////////////////////////////////////////////////////////
    // INITIALIZATION
    ////////////////////////////////////////////////////////////////////////////////

    constructor() {
        initialize(IMPL_INIT_NOOP_SAFE, IMPL_INIT_NOOP_ADDR);
    }

    function initialize(ISafe safe_, address trustedForwarder_) public {
        // calls SafeAware.__init_setSafe which reverts if already initialized
        __init_firmBase(safe_, trustedForwarder_);

        assert(_createRole(ONLY_ROOT_ROLE_AS_ADMIN, "Root") == ROOT_ROLE_ID);
        assert(_createRole(ONLY_ROOT_ROLE_AS_ADMIN, "Role Manager") == ROLE_MANAGER_ROLE_ID);

        // Safe given the root role on initialization (which admins for the role can revoke)
        // Addresses with the root role have permission to do anything
        // By assigning just the root role, it also gets the role manager role (and all roles to be created)
        getUserRoles[address(safe_)] = ONLY_ROOT_ROLE_AS_ADMIN;
    }

    ////////////////////////////////////////////////////////////////////////////////
    // ROLE CREATION AND MANAGEMENT
    ////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Creates a new role
     * @dev Requires the sender to hold the Role Manager role
     * @param roleAdmins Bitmap of roles that can perform admin actions on the new role
     * @param name Name of the role
     * @return roleId ID of the new role
     */
    function createRole(bytes32 roleAdmins, string memory name) public returns (uint8 roleId) {
        if (!hasRole(_msgSender(), ROLE_MANAGER_ROLE_ID)) {
            revert UnauthorizedNoRole(ROLE_MANAGER_ROLE_ID);
        }

        return _createRole(roleAdmins, name);
    }

    function _createRole(bytes32 roleAdmins, string memory name) internal returns (uint8 roleId) {
        uint256 roleId_ = roleCount;
        if (roleId_ == SAFE_OWNER_ROLE_ID) {
            revert RoleLimitReached();
        }

        if (roleAdmins == NO_ROLE_ADMINS || !_allRoleAdminsExist(roleAdmins, roleId_ + 1)) {
            revert InvalidRoleAdmins();
        }

        unchecked {
            roleId = uint8(roleId_);
            roleCount++;
        }

        getRoleAdmins[roleId] = roleAdmins;

        emit RoleCreated(roleId, roleAdmins, name, _msgSender());
    }

    /**
     * @notice Changes the roles that can perform admin actions on a role
     * @dev For the Root role, the sender must be an admin of Root
     * For all other roles, the sender should hold the Role Manager role
     * @param roleId ID of the role
     * @param roleAdmins Bitmap of roles that can perform admin actions on this role
     */
    function setRoleAdmins(uint8 roleId, bytes32 roleAdmins) external {
        if ((roleAdmins == NO_ROLE_ADMINS && roleId != ROOT_ROLE_ID) || !_allRoleAdminsExist(roleAdmins, roleCount)) {
            revert InvalidRoleAdmins();
        }

        if (!roleExists(roleId)) {
            revert UnexistentRole(roleId);
        }

        if (roleId == SAFE_OWNER_ROLE_ID) {
            revert UnauthorizedNotAdmin(SAFE_OWNER_ROLE_ID);
        }

        if (roleId == ROOT_ROLE_ID) {
            // Root role is treated as a special case. Only root role admins can change it
            if (!isRoleAdmin(_msgSender(), ROOT_ROLE_ID)) {
                revert UnauthorizedNotAdmin(ROOT_ROLE_ID);
            }
        } else {
            // For all other roles, the general role manager role can change any roles admins
            if (!hasRole(_msgSender(), ROLE_MANAGER_ROLE_ID)) {
                revert UnauthorizedNoRole(ROLE_MANAGER_ROLE_ID);
            }
        }

        getRoleAdmins[roleId] = roleAdmins;

        emit RoleAdminsSet(roleId, roleAdmins, _msgSender());
    }

    /**
     * @notice Changes the name of a role
     * @dev Requires the sender to hold the Role Manager role
     * @param roleId ID of the role
     * @param name New name for the role
     */
    function setRoleName(uint8 roleId, string memory name) external {
        if (!roleExists(roleId)) {
            revert UnexistentRole(roleId);
        }

        address sender = _msgSender();
        if (!hasRole(_msgSender(), ROLE_MANAGER_ROLE_ID)) {
            revert UnauthorizedNoRole(ROLE_MANAGER_ROLE_ID);
        }

        emit RoleNameChanged(roleId, name, sender);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // USER ROLE MANAGEMENT
    ////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Grants or revokes a role for a user
     * @dev Requires the sender to hold a role that is an admin for the role being set
     * @param user Address being granted or revoked the role
     * @param roleId ID of the role being granted or revoked
     * @param isGrant Whether the role is being granted or revoked
     */
    function setRole(address user, uint8 roleId, bool isGrant) external {
        if (roleId == SAFE_OWNER_ROLE_ID) {
            revert UnauthorizedNotAdmin(SAFE_OWNER_ROLE_ID);
        }

        bytes32 oldUserRoles = getUserRoles[user];
        bytes32 newUserRoles = oldUserRoles;

        address sender = _msgSender();
        // Implicitly checks that roleId had been created
        if (!_isRoleAdmin(sender, getUserRoles[sender], roleId)) {
            revert UnauthorizedNotAdmin(roleId);
        }

        if (isGrant) {
            newUserRoles |= bytes32(1 << roleId);
        } else {
            newUserRoles &= ~bytes32(1 << roleId);
        }

        getUserRoles[user] = newUserRoles;

        emit UserRolesChanged(user, oldUserRoles, newUserRoles, sender);
    }

    /**
     * @notice Grants and revokes a set of role for a user
     * @dev Requires the sender to hold roles that can admin all roles being set
     * @param user Address being granted or revoked the roles
     * @param grantingRoles ID of all roles being granted
     * @param revokingRoles ID of all roles being revoked
     */
    function setRoles(address user, uint8[] memory grantingRoles, uint8[] memory revokingRoles) external {
        address sender = _msgSender();
        bytes32 senderRoles = getUserRoles[sender];
        bytes32 oldUserRoles = getUserRoles[user];
        bytes32 newUserRoles = oldUserRoles;

        uint256 grantsLength = grantingRoles.length;
        for (uint256 i = 0; i < grantsLength;) {
            uint8 roleId = grantingRoles[i];
            if (roleId == SAFE_OWNER_ROLE_ID || !_isRoleAdmin(sender, senderRoles, roleId)) {
                revert UnauthorizedNotAdmin(roleId);
            }

            newUserRoles |= bytes32(1 << roleId);
            unchecked {
                i++;
            }
        }

        uint256 revokesLength = revokingRoles.length;
        for (uint256 i = 0; i < revokesLength;) {
            uint8 roleId = revokingRoles[i];
            if (roleId == SAFE_OWNER_ROLE_ID || !_isRoleAdmin(sender, senderRoles, roleId)) {
                revert UnauthorizedNotAdmin(roleId);
            }

            newUserRoles &= ~(bytes32(1 << roleId));
            unchecked {
                i++;
            }
        }

        getUserRoles[user] = newUserRoles;

        emit UserRolesChanged(user, oldUserRoles, newUserRoles, sender);
    }

    /**
     * @notice Checks whether a user holds a particular role
     * @param user Address being checked for if it holds the role
     * @param roleId ID of the role being checked
     * @return True if the user holds the role or has the root role
     */
    function hasRole(address user, uint8 roleId) public view returns (bool) {
        if (roleId == SAFE_OWNER_ROLE_ID) {
            return safe().isOwner(user) || _hasRootRole(getUserRoles[user]);
        }

        bytes32 userRoles = getUserRoles[user];
        // either user has the specified role or user has root role (whichs gives it permission to do anything)
        // Note: For root it will return true even if the role hasn't been created yet
        return uint256(userRoles >> roleId) & 1 != 0 || isRoleAdmin(user, roleId);
    }

    /**
     * @notice Checks whether a user has a role that can admin a particular role
     * @param user Address being checked for admin rights over the role
     * @param roleId ID of the role being checked
     * @return True if the user has admin rights over the role
     */
    function isRoleAdmin(address user, uint8 roleId) public view returns (bool) {
        // Safe owner role has no admin as it is a dynamic role (assigned and revoked by the Safe)
        return roleId < SAFE_OWNER_ROLE_ID ? _isRoleAdmin(user, getUserRoles[user], roleId) : false;
    }

    /**
     * @notice Checks whether a role exists
     * @param roleId ID of the role being checked
     * @return True if the role has been created
     */
    function roleExists(uint8 roleId) public view returns (bool) {
        return roleId == ROOT_ROLE_ID // Root role is allowed to be left without admins
            || roleId == SAFE_OWNER_ROLE_ID // Safe owner role doesn't have admins as it is a dynamic role
            || getRoleAdmins[roleId] != NO_ROLE_ADMINS; // All other roles must have admins if they exist
    }

    function _isRoleAdmin(address user, bytes32 userRoles, uint8 roleId) internal view returns (bool) {
        bytes32 roleAdmins = getRoleAdmins[roleId];

        // A user is considered an admin of a role if any of the following are true:
        // - User explicitly has a role that is an admin of the role
        // - User has the root role, the role exists, and the role checked is not the root role (allows for root to be left without admins)
        // - User is an owner of the safe and the safe owner role is an admin of the role

        return (userRoles & roleAdmins) != 0
            || (_hasRootRole(userRoles) && roleExists(roleId) && roleId != ROOT_ROLE_ID)
            || (uint256(roleAdmins >> SAFE_OWNER_ROLE_ID) & 1 != 0 && safe().isOwner(user));
    }

    function _hasRootRole(bytes32 userRoles) internal pure returns (bool) {
        // Since root role is always at ID 0, we don't need to shift
        return uint256(userRoles) & 1 != 0;
    }

    function _allRoleAdminsExist(bytes32 roleAdmins, uint256 _roleCount) internal pure returns (bool) {
        // Since the last roleId always exists, we remove that bit from the roleAdmins
        return uint256(roleAdmins & SAFE_OWNER_ROLE_MASK) < (1 << _roleCount);
    }
}