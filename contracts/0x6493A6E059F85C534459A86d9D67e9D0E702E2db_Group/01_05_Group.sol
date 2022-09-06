// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "../interfaces/IGroup.sol";

contract Group is Initializable, IGroup {
  uint256 public lastGroupId;

  mapping(address => mapping(uint256 => bool)) public userGroupIds;

  mapping(uint256 => GroupInfo) public groups;

  mapping(uint256 => mapping(address => bool)) public groupManagerRequests;


  struct GroupInfo {
    uint256 id;
    address owner;
    mapping(address => bool) managers;
    mapping(address => bool) members;
    bool joinByUser;
    uint256 membersLength;
    uint256 membersLimit;
    string name;
    string desc;
    uint256 orgId;
  }

  bool private _hasGroupMemberLimit;

  // Charge when the number of group members exceeds 500
  uint256 private constant DEFAULT_MEMBERS_LIMIT_FREE = 500;

  // Charge 1000 RNT to expand group members limit;
  uint256 private constant EXPAND_LIMIT_FEE = 1000;

  uint256 private constant MEMBERS_MAX_LIMIT = 1000000;

  mapping(uint256 => mapping(address => bool)) public groupMemberRequests;

  event GroupCreated(uint256 groupId, string name, string desc, bool joinByUser, address owner, address[] members);

  event GroupWithOrgCreated(uint256 orgId, uint256 groupId, string name, string desc, bool joinByUser, address owner, address[] members);

  event GroupJoinByUserUpdated(uint256 groupId, bool joinByUser,address owner);
 
  event GroupNameUpdated(uint256 groupId, string name,address owner);

  event GroupDescUpdated(uint256 groupId, string desc,address owner);

  event GroupRemoved(uint256 groupId, address owner);

  event GroupManagerRequested(uint256 groupId, address requestedBy);

  event GroupManagerRequestReceived(
    uint256 groupId,
    address requestedBy,
    address owner
  );

  event GroupManagerRequestRejected(
    uint256 groupId,
    address requestedBy,
    address owner
  );

  event GroupMemberRequested(uint256 groupId, address requestedBy);

  event GroupMemberRequestReceived(
    uint256 groupId,
    address requestedBy,
    address addedBy
  );

  event GroupMemberRequestRejected(
    uint256 groupId,
    address requestedBy,
    address addedBy
  );


  event GroupManagerAdded(uint256 groupId, address manager, address owner);

  event GroupManagerRemoved(uint256 groupId, address manager, address owner);

  event GroupMemberAdded(uint256 groupId, address addedBy, address[] members);

  event GroupMemberJoined(uint256 groupId, address member);

  event GroupMemberRemoved(uint256 groupId, address removedBy, address[] members);

  event GroupOwnerTransfered(
    uint256 groupId,
    address newOwner,
    address oldOwner
  );

  event GroupMembersLimitExpanded(uint256 groupId, address charger);

  event GroupMemberQuit(uint256 groupId, address member);

  /**
  * @dev Initialize this contract.
  */
  function initialize(bool hasGroupMemberLimit) external initializer {
    _hasGroupMemberLimit = hasGroupMemberLimit;
  }

  modifier onlyGroupOwner(uint256 groupId) {
    require(groups[groupId].owner == msg.sender, "Only group owner");
    _;
  }

  modifier onlyGroupManager(uint256 groupId) {
    require(groups[groupId].managers[msg.sender] == true, "Only group manager");
    _;
  }

  modifier onlyGroupMember(uint256 groupId) {
    require(groups[groupId].members[msg.sender] == true, "Only group member");
    _;
  }

  modifier groupExists(uint256 groupId) {
    require(groups[groupId].id == groupId, "Group not exists");
    _;
  }

  modifier onlyGroupOwnerOrManager(uint256 groupId) {
    bool isOwner = groups[groupId].owner == msg.sender;
    bool isManager = groups[groupId].managers[msg.sender] == true;
    require(isOwner || isManager, "Only group owner or manager");
    _;
  }

  modifier notExceedsLimit(uint256 groupId) {
    require(
      !_hasGroupMemberLimit ||
        groups[groupId].membersLength < groups[groupId].membersLimit,
      "Can not exceed members limit"
    );
    _;
  }

  /**
  * @dev Create a gruop
  * @param name Group's name.
  * @param desc Group's description.
  * @param joinByUser Whether allow users to join the group.
  * @param members Group members.
  */
  function createGroup(
    string calldata name,
    string calldata desc,
    bool joinByUser,
    address[] calldata members
  ) external override {
    uint256 _id = uint256(++lastGroupId);
    GroupInfo storage group = groups[_id];
    group.id = _id;
    group.name = name;
    group.desc = desc;
    group.owner = msg.sender;
    group.joinByUser = joinByUser;
    group.membersLength = members.length + 1;
    group.members[msg.sender] = true;
    for(uint i = 0; i < members.length; i++) {
      group.members[members[i]] = true;
      userGroupIds[members[i]][group.id] = true;
    }
    group.membersLimit = DEFAULT_MEMBERS_LIMIT_FREE;
    group.orgId = 0;

    userGroupIds[msg.sender][group.id] = true;
    emit GroupCreated(group.id, name, desc, joinByUser, msg.sender, members);
  }


  /**
  * @dev Create a gruop with organization id
  * @param oid Organization's id
  * @param name Group's name.
  * @param desc Group's description.
  * @param joinByUser Whether allow users to join the group.
  * @param members Group members.
  */
  function createGroupWithOrg(
    uint256 oid,
    string calldata name,
    string calldata desc,
    bool joinByUser,
    address[] calldata members
  ) external override {
    uint256 _id = uint256(++lastGroupId);
    GroupInfo storage group = groups[_id];
    group.orgId = oid;
    group.id = _id;
    group.name = name;
    group.desc = desc;
    group.owner = msg.sender;
    group.joinByUser = joinByUser;
    group.membersLength = members.length + 1;
    group.members[msg.sender] = true;
    for(uint i = 0; i < members.length; i++) {
      group.members[members[i]] = true;
      userGroupIds[members[i]][group.id] = true;
    }
    group.membersLimit = DEFAULT_MEMBERS_LIMIT_FREE;
    group.orgId = 0;

    userGroupIds[msg.sender][group.id] = true;
    emit GroupWithOrgCreated(oid, group.id, name, desc, joinByUser, msg.sender, members);
  }

  /**
  * @dev Update group's join rule.
  * @param groupId Id of the group.
  * @param _joinByUser Whether allow users to join the group.
  */
  function updateGroupJoinByUser(uint256 groupId, bool _joinByUser)
    external
    override
    groupExists(groupId)
    onlyGroupOwner(groupId)
  {
    groups[groupId].joinByUser = _joinByUser;
    emit GroupJoinByUserUpdated(groupId, _joinByUser, msg.sender);
  }

  /**
  * @dev Update group's name.
  * @param groupId Id of the group.
  * @param name New group name.
  */
  function updateGroupName(uint256 groupId, string calldata name)
    external
    override
    groupExists(groupId)
    onlyGroupOwner(groupId)
  {
    groups[groupId].name = name;
    emit GroupNameUpdated(groupId, name, msg.sender);
  }

  /**
  * @dev Update group's description.
  * @param groupId Id of the group.
  * @param desc New description.
  */
  function updateGroupDesc(uint256 groupId, string calldata desc)
    external
    override
    groupExists(groupId)
    onlyGroupOwner(groupId)
  {
    groups[groupId].desc = desc;
    emit GroupDescUpdated(groupId, desc, msg.sender);
  }

  // function chargeToExpandLimit(uint256 groupId) external override {
  //   require(
  //     groups[groupId].membersLimit == DEFAULT_MEMBERS_LIMIT_FREE,
  //     "Already expanded"
  //   );
  //   relationToken().transferFrom(msg.sender, address(this), EXPAND_LIMIT_FEE);
  //   groups[groupId].membersLimit = MEMBERS_MAX_LIMIT;
  //   emit GroupMembersLimitExpanded(groupId, msg.sender);
  // }

  /**
   * @dev Request to be the group manager.
   * @param groupId Id of the group.
  */
  function requestGroupManager(uint256 groupId)
    external
    override
    groupExists(groupId)
    onlyGroupMember(groupId)
  {
    require(
      groupManagerRequests[groupId][msg.sender] != true,
      "Can not request group manager twice"
    );
    require(groups[groupId].managers[msg.sender] != true, "Already group manager");
    groupManagerRequests[groupId][msg.sender] = true;
    emit GroupManagerRequested(groupId, msg.sender);
  }

  /**
   * @dev Receive the request to be group manager.
   * @param groupId Id of the group
   * @param user User who sent the request
   */
  function receiveGroupManagerRequest(uint256 groupId, address user)
    external
    override
    groupExists(groupId)
    onlyGroupOwner(groupId)
  {
    require(
      groupManagerRequests[groupId][user] == true,
      "Group manager request not exits"
    );
    require(groups[groupId].managers[user] != true, "Already group manager");
    groups[groupId].managers[user] = true;
    userGroupIds[user][groupId] = true;
    delete groupManagerRequests[groupId][user];
    emit GroupManagerRequestReceived(groupId, user, msg.sender);
  }

  /**
  * @dev Reject the request to be group manager
  * @param groupId Id of the group
  * @param user User who sent the request
  */
  function rejectGroupManagerRequest(uint256 groupId, address user)
    external
    override
    groupExists(groupId)
    onlyGroupOwner(groupId)
  {
    require(
      groupManagerRequests[groupId][user] == true,
      "Group manager request not exits"
    );
    require(groups[groupId].managers[user] != true, "Already group manager");
    groups[groupId].managers[user] = false;
    delete groupManagerRequests[groupId][user];
    emit GroupManagerRequestRejected(groupId, user, msg.sender);
  }

  /**
  * @dev Request to join the group
  * @param groupId Id of the group. 
  */
  function requestGroupMember(uint256 groupId)
    external
    override
    groupExists(groupId)
  {
    require(
      groupMemberRequests[groupId][msg.sender] != true,
      "Can not request group member twice"
    );
    require(groups[groupId].members[msg.sender] != true, "Already group member");
    groupMemberRequests[groupId][msg.sender] = true;
    emit GroupMemberRequested(groupId, msg.sender);
  }

  /**
  * @dev Receive the request to be the group member.
  * @param groupId Id of the group
  * @param user User who sent the request
  */
  function receiveGroupMemberRequest(uint256 groupId, address user)
    external
    override
    groupExists(groupId)
    onlyGroupOwnerOrManager(groupId)
  {
    require(
      groupMemberRequests[groupId][user] == true,
      "Group member request not exits"
    );
    require(groups[groupId].members[user] != true, "Already group member");
    groups[groupId].members[user] = true;
    userGroupIds[user][groupId] = true;
    delete groupMemberRequests[groupId][user];
    emit GroupMemberRequestReceived(groupId, user, msg.sender);
  }

  /**
  * @dev Reject the request to be the group member.
  * @param groupId Id of the group
  * @param user User who sent the request
  */
  function rejectGroupMemberRequest(uint256 groupId, address user)
    external
    override
    groupExists(groupId)
    onlyGroupOwnerOrManager(groupId)
  {
    require(
      groupMemberRequests[groupId][user] == true,
      "Group member request not exits"
    );
    require(groups[groupId].members[user] != true, "Already group member");
    groups[groupId].members[user] = false;
    delete groupMemberRequests[groupId][user];
    emit GroupMemberRequestRejected(groupId, user, msg.sender);
  }

  /**
  * @dev Add someone to be the group manager.
  * @param groupId Id of the group
  * @param manager Manager to add.
  */
  function addGroupManager(uint256 groupId, address manager)
    external
    override
    groupExists(groupId)
    onlyGroupOwner(groupId)
  {
    groups[groupId].managers[manager] = true;
    userGroupIds[manager][groupId] = true;
    emit GroupManagerAdded(groupId, manager, msg.sender);
  }

  /**
  * @dev Remove some group manager.
  * @param groupId Id of the group.
  * @param manager Manager to remove
   */
  function removeGroupManager(uint256 groupId, address manager)
    external
    override
    groupExists(groupId)
    onlyGroupOwner(groupId)
  {
    groups[groupId].managers[manager] = false;
    userGroupIds[manager][groupId] = false;
    emit GroupManagerRemoved(groupId, manager, msg.sender);
  }

  /**
  * @dev Add someone to join the group.
  * @param groupId Id of the group.
  * @param users Users to add.
   */
  function addGroupMember(uint256 groupId, address[] calldata users)
    external
    override
    groupExists(groupId)
    onlyGroupOwnerOrManager(groupId)
    notExceedsLimit(groupId)
  {
    for(uint i = 0; i < users.length; i++) {
      groups[groupId].members[users[i]] = true;
      userGroupIds[users[i]][groupId] = true;
      groups[groupId].membersLength++;
      if(groupMemberRequests[groupId][users[i]]) {
        delete groupMemberRequests[groupId][users[i]];
        emit GroupMemberRequestReceived(groupId, users[i], msg.sender);
      }
    }
    emit GroupMemberAdded(groupId, msg.sender, users);
  }

  /**
  * @dev Remove some group member.
  * @param groupId Id of the group
  * @param users Users to remove
   */
  function removeGroupMember(uint256 groupId, address[] calldata users)
    external
    override
    groupExists(groupId)
    onlyGroupOwnerOrManager(groupId)
  {
    for(uint i = 0; i < users.length; i++) {
      delete groups[groupId].members[users[i]];
      userGroupIds[users[i]][groupId] = false;
      groups[groupId].membersLength--;
      if(groups[groupId].managers[users[i]]){
        delete groups[groupId].managers[users[i]];
      }
    }
    emit GroupMemberRemoved(groupId, msg.sender, users);
  }

  /** 
  * @dev Remove some group
  * @param groupId Id of the group
   */
  function removeGroup(uint256 groupId)
    external
    override
    groupExists(groupId)
    onlyGroupOwner(groupId)
  {
    delete groups[groupId];
    emit GroupRemoved(groupId, msg.sender);
  }

  /**
   * @dev Join some group. The group must allow anyone to join.
   * @param groupId Id of the group to join
   */
  function joinGroup(uint256 groupId)
    external
    override
    groupExists(groupId)
    notExceedsLimit(groupId)
  {
    require(groups[groupId].joinByUser == true, "Can not join");
    groups[groupId].members[msg.sender] = true;
    userGroupIds[msg.sender][groupId] = true;
    groups[groupId].membersLength++;
    emit GroupMemberJoined(groupId, msg.sender);
  }

  /**
   * @dev Group member quit group.
   * @param groupId Id of the group to quit.
   */
  function quitGroup(uint256 groupId) 
    external
    override
    groupExists(groupId)
  {
    require(groups[groupId].members[msg.sender] == true, "Not member");
    require(userGroupIds[msg.sender][groupId] == true, "Not in group");
    groups[groupId].members[msg.sender] = false;
    userGroupIds[msg.sender][groupId] = false;
    groups[groupId].membersLength--;
    emit GroupMemberQuit(groupId, msg.sender);
  }

  /** 
   * @dev Transfer the ownershipt of some group to other user.
   * @param groupId Id of the group to transfer ownership.
   * @param newOwner New owner of the group.
   */
  function transferGroupOwner(uint256 groupId, address newOwner)
    external
    override
    groupExists(groupId)
    onlyGroupOwner(groupId)
  {
    groups[groupId].owner = newOwner;
    userGroupIds[msg.sender][groupId] = false;
    emit GroupOwnerTransfered(groupId, newOwner, msg.sender);
  }

  /**
   * @dev Verify if the group exists.
   * @param groupId  Group id to verify.
   */
  function verifyGroupId(uint256 groupId)
    external
    view
    override
    returns (bool)
  {
    return groups[groupId].id == groupId;
  }

  /**
   * @dev Check if user is in the group.
   * @param groupId Id of the group.
   */
  function isInGroup(uint256 groupId, address user) external view override returns (bool) {
    return userGroupIds[user][groupId] == true;
  }
}