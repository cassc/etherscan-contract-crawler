// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// OpenZeppelin imports
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

/**************************************

    AccessControl library

    ------------------------------

    Diamond storage containing access control data

 **************************************/

/// @notice Fork of OpenZeppelin's AccessControl that fits as diamond proxy library.
library LibAccessControl {
    // -----------------------------------------------------------------------
    //                              Storage pointer
    // -----------------------------------------------------------------------

    /// @dev Access control storage pointer.
    bytes32 constant ACCESS_CONTROL_STORAGE_POSITION = keccak256("angelblock.access.control");

    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    /// @dev Default admin role
    bytes32 public constant ADMIN_ROLE = 0x00;

    // -----------------------------------------------------------------------
    //                                  Structs
    // -----------------------------------------------------------------------

    /// @dev Struct containing role settings.
    /// @param members Mapping of addresses, that returns True if user is a member
    /// @param adminRole Byte-encoded string of admin role for given role
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    /// @dev Access control storage struct.
    /// @param roles Mapping of byte-encoded strings of roles to RoleData struct
    /// @param initialized Used to allow and keep track of admin to be created once
    struct AccessControlStorage {
        mapping(bytes32 => RoleData) roles;
        bool initialized;
    }

    // -----------------------------------------------------------------------
    //                                  Events
    // -----------------------------------------------------------------------

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    // -----------------------------------------------------------------------
    //                                  Errors
    // -----------------------------------------------------------------------

    error CannotSetAdminForAdmin(); // 0x625dd4af
    error CanOnlyRenounceSelf(); // 0x4b47a2fd

    // -----------------------------------------------------------------------
    //                                  Modifiers
    // -----------------------------------------------------------------------

    /// @dev Modifier that checks if caller has given role.
    /// @dev Validation: Expect caller to be a member of role.
    /// @param _role Expected role for sender to be a member of
    modifier onlyRole(bytes32 _role) {
        // check role
        if (!hasRole(_role, msg.sender)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(msg.sender),
                        " is missing role ",
                        Strings.toHexString(uint256(_role), 32)
                    )
                )
            );
        }
        _;
    }

    // -----------------------------------------------------------------------
    //                                  Diamond storage
    // -----------------------------------------------------------------------

    /// @dev Function returning access control storage at storage pointer slot.
    /// @return acs AccessControlStorage struct instance at storage pointer position
    function accessStorage() internal pure returns (AccessControlStorage storage acs) {
        // declare position
        bytes32 position = ACCESS_CONTROL_STORAGE_POSITION;

        // set slot to position
        assembly {
            acs.slot := position
        }

        // explicit return
        return acs;
    }

    // -----------------------------------------------------------------------
    //                              Getters / setters
    // -----------------------------------------------------------------------

    /// @dev Diamond storage getter: roles->hasRole(account).
    /// @param _role Byte-encoded role
    /// @param _account Address to check role
    /// @return True if account is member of given role
    function hasRole(bytes32 _role, address _account) internal view returns (bool) {
        // return
        return accessStorage().roles[_role].members[_account];
    }

    /// @dev Diamond storage setter: roles->setAdmin(account).
    /// @param _account Address to become an admin
    function createAdmin(address _account) internal {
        // set role
        accessStorage().roles[ADMIN_ROLE].members[_account] = true;
    }

    /// @dev Diamond storage getter: roles->getAdminRole(role).
    /// @param _role Byte-encoded role
    /// @return Admin role for given role
    function getRoleAdmin(bytes32 _role) internal view returns (bytes32) {
        // return
        return accessStorage().roles[_role].adminRole;
    }

    /// @dev Diamond storage setter: roles->setAdminRole(role).
    /// @dev Validation: Only main admin role can change admin role for given role.
    /// @dev Validation: Admin role for default admin role cannot be changed.
    /// @param _role Byte-encoded role to set admin role
    /// @param _adminRole Byte-encoded admin role for given role
    function setRoleAdmin(bytes32 _role, bytes32 _adminRole) internal onlyRole(ADMIN_ROLE) {
        // accept each role except admin
        if (_role != ADMIN_ROLE) accessStorage().roles[_role].adminRole = _adminRole;
        else revert CannotSetAdminForAdmin();
    }

    // -----------------------------------------------------------------------
    //                              Functions
    // -----------------------------------------------------------------------

    /**************************************

        Grant role

     **************************************/

    /// @dev Grant role to an account.
    /// @dev Validation: Can only be called by the admin of the role.
    /// @dev Validation: Will not grant role if account already has a desired role.
    /// @dev Events: RoleGranted(bytes32 role, address account, address sender).
    /// @param _role Byte-encoded role
    /// @param _account Address to receive a role
    function grantRole(bytes32 _role, address _account) internal onlyRole(getRoleAdmin(_role)) {
        // grant
        _grantRole(_role, _account);
    }

    /**************************************

        Revoke role

     **************************************/

    /// @dev Revoke role of account. Will not revoke role if account doesn't have it.
    /// @dev Validation: Can only be called by the admin of the role.
    /// @dev Events: RoleRevoked(bytes32 role, address account, address sender).
    /// @param _role Byte-encoded role
    /// @param _account Address of account that has role
    function revokeRole(bytes32 _role, address _account) internal onlyRole(getRoleAdmin(_role)) {
        // revoke
        _revokeRole(_role, _account);
    }

    /**************************************

        Renounce role

     **************************************/

    /// @dev Renounce role of account. Will not renounce role if account doesn't have it.
    /// @dev Validation: Can only be called by the user that has role.
    /// @dev Events: RoleRevoked(bytes32 role, address account, address sender).
    /// @param _role Byte-encoded role
    /// @param _account Address of account that has role
    function renounceRole(bytes32 _role, address _account) internal {
        // check sender
        if (_account != msg.sender) {
            revert CanOnlyRenounceSelf();
        }

        // revoke
        _revokeRole(_role, _account);
    }

    /**************************************

        Low level: grant

     **************************************/

    /// @dev Grant role to an account.
    /// @dev Validation: Will not grant role if account already has a desired role.
    /// @dev Events: RoleGranted(bytes32 role, address account, address sender).
    /// @param _role Byte-encoded role
    /// @param _account Address to receive a role
    function _grantRole(bytes32 _role, address _account) private {
        // check if not have role already
        if (!hasRole(_role, _account)) {
            // grant role
            accessStorage().roles[_role].members[_account] = true;

            // event
            emit RoleGranted(_role, _account, msg.sender);
        }
    }

    /**************************************

        Low level: revoke

     **************************************/

    /// @dev Revoke role of an account. Will not revoke role if account doesn't have it.
    /// @dev Events: RoleRevoked(bytes32 role, address account, address sender).
    /// @param _role Byte-encoded role
    /// @param _account Address of account that has role
    function _revokeRole(bytes32 _role, address _account) private {
        // check if have role
        if (hasRole(_role, _account)) {
            // revoke role
            accessStorage().roles[_role].members[_account] = false;

            // event
            emit RoleRevoked(_role, _account, msg.sender);
        }
    }
}