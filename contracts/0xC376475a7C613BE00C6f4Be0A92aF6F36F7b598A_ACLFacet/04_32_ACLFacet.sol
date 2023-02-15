// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LibACL, LibHelpers } from "../libs/LibACL.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibDiamond } from "../../shared/libs/LibDiamond.sol";
import { Modifiers } from "../Modifiers.sol";
import { IACLFacet } from "../interfaces/IACLFacet.sol";

/**
 * @title Access Control List
 * @notice Use it to authorize various actions on the contracts
 * @dev Use it to (un)assign or check role membership
 */
contract ACLFacet is Modifiers, IACLFacet {
    /**
     * @notice Assign a `_roleId` to the object in given context
     * @dev Any object ID can be a context, system is a special context with highest priority
     * @param _objectId ID of an object that is being assigned a role
     * @param _contextId ID of the context in which a role is being assigned
     * @param _role Name of the role being assigned
     */
    function assignRole(
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _role
    ) external {
        bytes32 assignerId = LibHelpers._getIdForAddress(msg.sender);
        require(LibACL._canAssign(assignerId, _objectId, _contextId, LibHelpers._stringToBytes32(_role)), "not in assigners group");
        LibACL._assignRole(_objectId, _contextId, LibHelpers._stringToBytes32(_role));
    }

    /**
     * @notice Unassign object from a role in given context
     * @dev Any object ID can be a context, system is a special context with highest priority
     * @param _objectId ID of an object that is being unassigned from a role
     * @param _contextId ID of the context in which a role membership is being revoked
     */
    function unassignRole(bytes32 _objectId, bytes32 _contextId) external {
        bytes32 roleId = LibACL._getRoleInContext(_objectId, _contextId);
        bytes32 assignerId = LibHelpers._getIdForAddress(msg.sender);
        require(LibACL._canAssign(assignerId, _objectId, _contextId, roleId), "not in assigners group");
        LibACL._unassignRole(_objectId, _contextId);
    }

    /**
     * @notice Checks if an object belongs to `_group` group in given context
     * @dev Assigning a role to the object makes it a member of a corresponding role group
     * @param _objectId ID of an object that is being checked for role group membership
     * @param _contextId Context in which memebership should be checked
     * @param _group name of the role group
     * @return true if object with given ID is a member, false otherwise
     */
    function isInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _group
    ) external view returns (bool) {
        return LibACL._isInGroup(_objectId, _contextId, LibHelpers._stringToBytes32(_group));
    }

    /**
     * @notice Check whether a parent object belongs to the `_group` group in given context
     * @dev Objects can have a parent object, i.e. entity is a parent of a user
     * @param _objectId ID of an object whose parent is being checked for role group membership
     * @param _contextId Context in which the role group membership is being checked
     * @param _group name of the role group
     * @return true if object's parent is a member of this role group, false otherwise
     */
    function isParentInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _group
    ) external view returns (bool) {
        return LibACL._isParentInGroup(_objectId, _contextId, LibHelpers._stringToBytes32(_group));
    }

    /**
     * @notice Check whether a user can assign specific object to the `_role` role in given context
     * @dev Check permission to assign to a role
     * @param _assignerId The object ID of the user who is assigning a role to  another object.
     * @param _objectId ID of an object that is being checked for assigning rights
     * @param _contextId ID of the context in which permission is checked
     * @param _role name of the role to check
     * @return true if user the right to assign, false otherwise
     */
    function canAssign(
        bytes32 _assignerId,
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _role
    ) external view returns (bool) {
        return LibACL._canAssign(_assignerId, _objectId, _contextId, LibHelpers._stringToBytes32(_role));
    }

    /**
     * @notice Get a user's (an objectId's) assigned role in a specific context
     * @param objectId ID of an object that is being checked for its assigned role in a specific context
     * @param contextId ID of the context in which the objectId's role is being checked
     * @return roleId objectId's role in the contextId
     */
    function getRoleInContext(bytes32 objectId, bytes32 contextId) external view returns (bytes32) {
        return LibACL._getRoleInContext(objectId, contextId);
    }

    /**
     * @notice Get whether role is in group.
     * @dev Get whether role is in group.
     * @param role the role.
     * @param group the group.
     * @return true if role is in group, false otherwise.
     */
    function isRoleInGroup(string memory role, string memory group) external view returns (bool) {
        return LibACL._isRoleInGroup(role, group);
    }

    /**
     * @notice Get whether given group can assign given role.
     * @dev Get whether given group can assign given role.
     * @param role the role.
     * @param group the group.
     * @return true if role can be assigned by group, false otherwise.
     */
    function canGroupAssignRole(string memory role, string memory group) external view returns (bool) {
        return LibACL._canGroupAssignRole(role, group);
    }

    /**
     * @notice Update who can assign `_role` role
     * @dev Update who has permission to assign this role
     * @param _role name of the role
     * @param _assignerGroup Group who can assign members to this role
     */
    function updateRoleAssigner(string memory _role, string memory _assignerGroup) external assertSysAdmin {
        LibACL._updateRoleAssigner(_role, _assignerGroup);
    }

    /**
     * @notice Update role group memebership for `_role` role and `_group` group
     * @dev Update role group memebership
     * @param _role name of the role
     * @param _group name of the group
     * @param _roleInGroup is member of
     */
    function updateRoleGroup(
        string memory _role,
        string memory _group,
        bool _roleInGroup
    ) external assertSysAdmin {
        require(!strEquals(_group, LibConstants.GROUP_SYSTEM_ADMINS), "system admins group is not modifiable");
        LibACL._updateRoleGroup(_role, _group, _roleInGroup);
    }

    function strEquals(string memory s1, string memory s2) private pure returns (bool) {
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
}