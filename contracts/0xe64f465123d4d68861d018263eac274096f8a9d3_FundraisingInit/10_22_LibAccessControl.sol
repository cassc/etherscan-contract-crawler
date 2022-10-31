// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
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

library LibAccessControl {

    // storage pointer
    bytes32 constant ACCESS_CONTROL_STORAGE_POSITION = keccak256("angelblock.access.control");
    bytes32 constant ADMIN_ROLE = 0x0;

    // structs: data containers
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }
    struct AccessControlStorage {
        mapping(bytes32 => RoleData) roles;
        bool initialized;
    }

    // diamond storage getter
    function accessStorage() internal pure
    returns (AccessControlStorage storage acs) {

        // declare position
        bytes32 position = ACCESS_CONTROL_STORAGE_POSITION;

        // set slot to position
        assembly {
            acs.slot := position
        }

        // explicit return
        return acs;

    }

    // events
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    // errors
    error CannotSetAdminForAdmin();
    error CanOnlyRenounceSelf();
    error OneTimeFunction();

    // modifiers
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
    modifier oneTime() {

        // storage
        AccessControlStorage storage acs = accessStorage();

        // initialize
        if (!acs.initialized) {
            acs.initialized = true;
            _;
        } else {
            revert OneTimeFunction();
        }

    }

    // diamond storage getter: has role
    function hasRole(bytes32 _role, address _account) internal view 
    returns (bool) {

        // return
        return accessStorage().roles[_role].members[_account];

    }

    // diamond storage setter: set role
    function createAdmin(address _account) internal oneTime() {

        // set role
        accessStorage().roles[ADMIN_ROLE].members[_account] = true;

    }

    // diamond storage getter: has admin role
    function getRoleAdmin(bytes32 _role) internal view 
    returns (bytes32) {

        // return
        return accessStorage().roles[_role].adminRole;

    }

    // diamond storage setter: set admin role
    function setRoleAdmin(bytes32 _role, bytes32 _adminRole) internal onlyRole(ADMIN_ROLE) {

        // accept each role except admin
        if (_role != ADMIN_ROLE) accessStorage().roles[_role].adminRole = _adminRole;
        else revert CannotSetAdminForAdmin();

    }

    /**************************************

        Grant role

     **************************************/

    function grantRole(bytes32 _role, address _account) internal onlyRole(getRoleAdmin(_role)) {

        // grant
        _grantRole(_role, _account);

    }

    /**************************************

        Revoke role

     **************************************/

    function revokeRole(bytes32 _role, address _account) internal onlyRole(getRoleAdmin(_role)) {

        // revoke
        _revokeRole(_role, _account);

    }

    /**************************************

        Renounce role

     **************************************/

    function renounceRole(bytes32 role, address account) internal {

        // check sender
        if (account != msg.sender) {
            revert CanOnlyRenounceSelf();
        }

        // revoke
        _revokeRole(role, account);

    }

    /**************************************

        Low level: grant

     **************************************/

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