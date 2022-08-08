// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IGroup {
  function createGroup(
    string calldata name,
    string calldata desc,
    bool joinByUser,
    address[] calldata members
  ) external;

  function createGroupWithOrg(
    uint256 oid,
    string calldata name,
    string calldata desc,
    bool joinByUser,
    address[] calldata members
  ) external;

  function updateGroupJoinByUser(uint256 groupId, bool _joinByUser)
    external;
  
  function updateGroupName(uint256 groupId, string calldata name)
    external;
  
  function updateGroupDesc(uint256 groupId, string calldata desc)
    external;

  function requestGroupManager(uint256 groupId) external;

  function receiveGroupManagerRequest(uint256 groupId, address user) external;

  function rejectGroupManagerRequest(uint256 groupId, address user) external;

  function requestGroupMember(uint256 groupId) external;

  function receiveGroupMemberRequest(uint256 groupId, address user) external;

  function rejectGroupMemberRequest(uint256 groupId, address user) external;
  
  function addGroupManager(uint256 groupId, address manager) external;

  function removeGroupManager(uint256 groupId, address manager) external;

  function removeGroup(uint256 groupId) external;

  function addGroupMember(uint256 groupId, address[] calldata users) external;

  function removeGroupMember(uint256 groupId, address[] calldata users) external;

  function joinGroup(uint256 groupId) external;

  function quitGroup(uint256 groupId) external;

  function transferGroupOwner(uint256 groupId, address newOwner) external;

  function verifyGroupId(uint256 groupId) external returns (bool);

  function isInGroup(uint256 groupId, address user) external view returns (bool);

}