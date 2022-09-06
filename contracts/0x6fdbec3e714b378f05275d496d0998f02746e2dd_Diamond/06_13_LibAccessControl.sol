// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IAccessControl} from "../interfaces/IAccessControl.sol";
import {LibStrings} from "./LibStrings.sol";

library AccessControl {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct AccessControlStorage {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant SEC_MULTISIG_ROLE = keccak256("SEC_MULTISIG_ROLE");
    bytes32 public constant PAYEE_ROLE = keccak256("PAYEE_ROLE");
    bytes32 public constant ACCESS_CONTROL_STORAGE = keccak256("lol.momentum.access_control");
    

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /// @notice Modifier that checks that an account has a specific role. Reverts
    /// with a standardized message including the required role.
    /// @dev The format of the revert reason is given by the following regular expression:
    /// /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
    /// @param role a role referred to by their `bytes32` identifier.
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /// @notice Grants `role` to `member`.
    /// @dev the caller must have ``role``'s admin role.
    /// @param role Roles are referred to by their `bytes32` identifier.
    /// @param account If `member` had not been already granted `role`, emits a {RoleGranted}
    /// event.
    function grantRole(bytes32 role, address account) public onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }


    /// @notice Revokes `role` from `account`.
    /// @dev the caller must have ``role``'s admin role.
    /// @param role the `bytes32` identifier of the role.
    /// @param account If `account` had been granted `role`, emits a {RoleRevoked} event.
    function revokeRole(bytes32 role, address account) public onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }


    /// @notice Revokes `role` from the calling account.
    /// @dev Roles are often managed via {grantRole} and {revokeRole}: this function's
    /// purpose is to provide a mechanism for accounts to lose their privileges
    /// if they are compromised (such as when a trusted device is misplaced).
    /// @param role the `bytes32` identifier of the role.
    /// @param account the caller must be `account`, emits a {RoleRevoked} event.
    function renounceRole(bytes32 role, address account) public {
        require(account == msg.sender, "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }


    /// @notice Check that account has role
    /// @param role a role referred to by their `bytes32` identifier.
    /// @param account the account to check
    /// @return  Returns `true` if `account` has been granted `role`.
    function hasRole(bytes32 role, address account) public view returns (bool) {
        AccessControlStorage storage acs = accessControlStorage();
        return acs.roles[role].members[account];
    }


    /// @notice Returns the admin role that controls `role`
    /// @dev See {grantRole} and {revokeRole}. To change a role's admin, use {_setRoleAdmin}.
    /// @param role the `bytes32` identifier of the role.
    /// @return Returns the admin role that controls `role`
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        AccessControlStorage storage acs = accessControlStorage();
        return acs.roles[role].adminRole;
    }


    function initialize(address defaultAdmin) internal {
        AccessControlStorage storage ac = accessControlStorage();
        ac.roles[DEFAULT_ADMIN_ROLE].members[defaultAdmin] = true;
        emit RoleGranted(DEFAULT_ADMIN_ROLE, defaultAdmin, msg.sender);
    }
   

    /*function _setupRole(bytes32 role, address account) internal {
        _grantRole(role, account);
    }*/


    /// @notice Sets `adminRole` as ``role``'s admin role.
    /// @dev Emits a {RoleAdminChanged} event.
    /// @param role the `bytes32` identifier of the role.
    /// @param adminRole the `bytes32` identifier of the adminRole.
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        AccessControlStorage storage acs = accessControlStorage();
        bytes32 previousAdminRole = getRoleAdmin(role);
        acs.roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }


    /// @notice Grants `role` to `member`.
    /// @dev the caller must have ``role``'s admin role.
    /// @param role Roles are referred to by their `bytes32` identifier.
    /// @param account If `member` had not been already granted `role`, emits a {RoleGranted}
    /// event.
    function _grantRole(bytes32 role, address account) internal {
        AccessControlStorage storage acs = accessControlStorage();
        if (!hasRole(role, account)) {
            acs.roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }


    /// @notice Revokes `role` from `account`.
    /// @dev the caller must have ``role``'s admin role.
    /// @param role the `bytes32` identifier of the role.
    /// @param account If `account` had been granted `role`, emits a {RoleRevoked} event.
    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            AccessControlStorage storage acs = accessControlStorage();
            acs.roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
    

    /// @notice Revert with a standard message if `_msgSender()` is missing `role`.
    /// Overriding this function changes the behavior of the {onlyRole} modifier.
    /// @dev Format of the revert message is described in {_checkRole}.
    /// @param role a role referred to by their `bytes32` identifier.
    function _checkRole(bytes32 role) internal view {
        _checkRole(role, msg.sender);
    }


    /// @notice Check that accout has the role
    /// @dev The format of the revert reason is given by the following regular expression:
    /// /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
    /// @param role a role referred to by their `bytes32` identifier.
    /// @param account Revert with a standard message if `account` is missing `role`.
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        LibStrings.toHexString(account),
                        " is missing role ",
                        LibStrings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }


    /// @notice Get the Storage used for this facet
    /// @return acs the AccessControlStorage
    function accessControlStorage() internal pure returns (AccessControlStorage storage acs) {
        bytes32 position = ACCESS_CONTROL_STORAGE;
        assembly {
            acs.slot := position
        }
    }
}