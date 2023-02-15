// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibObject } from "./LibObject.sol";
import { LibConstants } from "./LibConstants.sol";
import { RoleIsMissing, AssignerGroupIsMissing } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

library LibACL {
    /**
     * @dev Emitted when a role gets updated. Empty roleId is assigned upon role removal
     * @param objectId The user or object that was assigned the role.
     * @param contextId The context where the role was assigned to.
     * @param assignedRoleId The ID of the role which got (un)assigned. (empty ID when unassigned)
     * @param functionName The function performing the action
     */
    event RoleUpdate(bytes32 indexed objectId, bytes32 contextId, bytes32 assignedRoleId, string functionName);
    /**
     * @dev Emitted when a role group gets updated.
     * @param role The role name.
     * @param group the group name.
     * @param roleInGroup whether the role is now in the group or not.
     */
    event RoleGroupUpdated(string role, string group, bool roleInGroup);
    /**
     * @dev Emitted when a role assigners gets updated.
     * @param role The role name.
     * @param group the name of the group that can now assign this role.
     */
    event RoleCanAssignUpdated(string role, string group);

    function _assignRole(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _roleId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_objectId != "", "invalid object ID");
        require(_contextId != "", "invalid context ID");
        require(_roleId != "", "invalid role ID");

        s.roles[_objectId][_contextId] = _roleId;

        if (_contextId == LibAdmin._getSystemId() && _roleId == LibHelpers._stringToBytes32(LibConstants.ROLE_SYSTEM_ADMIN)) {
            unchecked {
                s.sysAdmins += 1;
            }
        }

        emit RoleUpdate(_objectId, _contextId, _roleId, "_assignRole");
    }

    function _unassignRole(bytes32 _objectId, bytes32 _contextId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 roleId = s.roles[_objectId][_contextId];
        if (_contextId == LibAdmin._getSystemId() && roleId == LibHelpers._stringToBytes32(LibConstants.ROLE_SYSTEM_ADMIN)) {
            require(s.sysAdmins > 1, "must have at least one system admin");
            unchecked {
                s.sysAdmins -= 1;
            }
        }

        emit RoleUpdate(_objectId, _contextId, s.roles[_objectId][_contextId], "_unassignRole");
        delete s.roles[_objectId][_contextId];
    }

    function _isInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _groupId
    ) internal view returns (bool ret) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Check for the role in the context
        bytes32 objectRoleInContext = s.roles[_objectId][_contextId];

        if (objectRoleInContext != 0 && s.groups[objectRoleInContext][_groupId]) {
            ret = true;
        } else {
            // A role in the context of the system covers all objects
            bytes32 objectRoleInSystem = s.roles[_objectId][LibAdmin._getSystemId()];

            if (objectRoleInSystem != 0 && s.groups[objectRoleInSystem][_groupId]) {
                ret = true;
            }
        }
    }

    function _isParentInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _groupId
    ) internal view returns (bool) {
        bytes32 parentId = LibObject._getParent(_objectId);
        return _isInGroup(parentId, _contextId, _groupId);
    }

    /**
     * @notice Checks if assigner has the authority to assign object to a role in given context
     * @dev Any object ID can be a context, system is a special context with highest priority
     * @param _assignerId ID of an account wanting to assign a role to an object
     * @param _objectId ID of an object that is being assigned a role
     * @param _contextId ID of the context in which a role is being assigned
     * @param _roleId ID of a role being assigned
     */
    function _canAssign(
        bytes32 _assignerId,
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _roleId
    ) internal view returns (bool) {
        // we might impose additional restrictions on _objectId in the future
        require(_objectId != "", "invalid object ID");

        bool ret = false;
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 assignerGroup = s.canAssign[_roleId];

        // assigners group undefined
        if (assignerGroup == 0) {
            ret = false;
        }
        // Check for assigner's group membership in given context
        else if (_isInGroup(_assignerId, _contextId, assignerGroup)) {
            ret = true;
        }
        // Otherwise, check his parent's membership in system context
        // if account itself does not have the membership in given context, then having his parent
        // in the system context grants him the privilege needed
        else if (_isParentInGroup(_assignerId, LibAdmin._getSystemId(), assignerGroup)) {
            ret = true;
        }

        return ret;
    }

    function _getRoleInContext(bytes32 _objectId, bytes32 _contextId) internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.roles[_objectId][_contextId];
    }

    function _isRoleInGroup(string memory role, string memory group) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.groups[LibHelpers._stringToBytes32(role)][LibHelpers._stringToBytes32(group)];
    }

    function _canGroupAssignRole(string memory role, string memory group) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.canAssign[LibHelpers._stringToBytes32(role)] == LibHelpers._stringToBytes32(group);
    }

    function _updateRoleAssigner(string memory _role, string memory _assignerGroup) internal {
        if (bytes32(bytes(_role)) == "") {
            revert RoleIsMissing();
        }
        if (bytes32(bytes(_assignerGroup)) == "") {
            revert AssignerGroupIsMissing();
        }
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.canAssign[LibHelpers._stringToBytes32(_role)] = LibHelpers._stringToBytes32(_assignerGroup);
        emit RoleCanAssignUpdated(_role, _assignerGroup);
    }

    function _updateRoleGroup(
        string memory _role,
        string memory _group,
        bool _roleInGroup
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (bytes32(bytes(_role)) == "") {
            revert RoleIsMissing();
        }
        if (bytes32(bytes(_group)) == "") {
            revert AssignerGroupIsMissing();
        }

        s.groups[LibHelpers._stringToBytes32(_role)][LibHelpers._stringToBytes32(_group)] = _roleInGroup;
        emit RoleGroupUpdated(_role, _group, _roleInGroup);
    }
}