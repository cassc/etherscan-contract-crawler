// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "../interfaces/IFriend.sol";

contract Friend is Initializable, IFriend {
  mapping(address => mapping(address => bool)) public friendRelations;

  mapping(address => bytes32[]) public friendRequestTags;

  mapping(address => mapping(address => bool)) public friendRequests;

  mapping(address => mapping(address => bool)) public blockList;

  mapping(address => mapping(address => uint256)) public friendRequestGifts;

  // For decentralized chat app
  mapping(address => ServerInfo) public userServerInfos;

  struct ServerInfo {
    string pubkey;
    string server;
  }

  event FriendRequested(address sender, address receiver);

  event FriendRequestedWithGift(address sender, uint256 gift, address receiver);

  event FriendRequestReceived(address receiver, address inviter);

  event FriendRequestRejected(address receiver, address inviter);

  event UserBlocked(address blocked, address blockedBy);

  event UserUnblocked(address unblocked, address unblockedBy);

  event FriendRemoved(address friend, address removedBy);

  event FriendRequestTagsSet(address user, bytes32[] tags);

  event ServerInfoUpdated(address user, string pubkey, string server);

  function initialize() external initializer {}


  /**
  * Update server info for decentralized chat app. Each user will have one server.
 */ 
  function updateServerInfo(string calldata _pubkey, string calldata _server) external {
    //TODO verify pk is valid
    userServerInfos[msg.sender] = ServerInfo({
      pubkey: _pubkey,
      server: _server
    });
    emit ServerInfoUpdated(msg.sender, _pubkey, _server);
  }

  /** 
  * Deprecated. 
  */
  function setRequestTags(bytes32[] calldata tags) external {
    friendRequestTags[msg.sender] = tags;
  }

  /**
   * @dev Request friend.
   * @param receiver Who will receive the request.
   */
  function requestFriend(address receiver) external {
    require(blockList[receiver][msg.sender] != true, "You are blocked");
    require(
      friendRequests[receiver][msg.sender] != true,
      "Can not request friend twice"
    );
    require(
      friendRelations[receiver][msg.sender] != true,
      "You are already friend"
    );
    friendRequests[receiver][msg.sender] = true;
    emit FriendRequested(msg.sender, receiver);
  }

  /**
   * Deprecated
   */
  function requestFriendWithGift(address receiver, uint256 gift) external {
    require(blockList[receiver][msg.sender] != true, "You are blocked");
    require(
      friendRequests[receiver][msg.sender] != true,
      "Can not request friend twice"
    );
    require(
      friendRelations[receiver][msg.sender] != true,
      "You are already friend"
    );
    friendRequests[receiver][msg.sender] = true;
    emit FriendRequestedWithGift(msg.sender, gift, receiver);
  }


  /**
   * @dev Receive the friend request.
   * @param inviter Who sent the request.
   */
  function receiveFriendRequest(address inviter) external {
    require(friendRequests[msg.sender][inviter] == true, "No friend request");
    friendRelations[msg.sender][inviter] = true;
    friendRelations[inviter][msg.sender] = true;
    delete friendRequests[msg.sender][inviter];
    emit FriendRequestReceived(msg.sender, inviter);
  }

  /**
   * @dev Reject the friend request.
   * @param inviter Who sent the request.
   * @param ifBlock If block the inviter at the same time.
   */  
  function rejectFriendRequest(address inviter, bool ifBlock) external {
    require(friendRequests[msg.sender][inviter] == true, "No friend request");
    if (ifBlock) {
      blockList[msg.sender][inviter] = true;
    }
    delete friendRequests[msg.sender][inviter];
    delete friendRequestGifts[msg.sender][inviter];
    emit FriendRequestRejected(msg.sender, inviter);
  }

  /** 
  * @dev Block some user that he/she can not send friend request to you again.
  * @param user User to block.
  */
  function blockUser(address user) external {
    blockList[msg.sender][user] = true;
    emit UserBlocked(user, msg.sender);
  }

  /**
   * @dev Unblock some user that he/she can send friend request to you again.
   * @param user User to unblock.
   */
  function unblockUser(address user) external {
    blockList[msg.sender][user] = false;
    emit UserUnblocked(user, msg.sender);
  }

  /**
   * @dev Remove friend of you.
   * @param friend Friend to remove
   */
  function removeFriend(address friend) external {
    require(
      friendRelations[msg.sender][friend] == true,
      "Can not remove non-friend"
    );
    friendRelations[msg.sender][friend] = false;
    friendRelations[friend][msg.sender] = false;
    emit FriendRemoved(friend, msg.sender);
  }

  /**
   * @dev Check if two addresses are friends.
   * @param alice Address one.
   * @param bob Address two.
   * @return Is friend or not.
   */
  function isFriend(address alice, address bob)
    external
    view
    override
    returns (bool)
  {
    return
      friendRelations[alice][bob] == true &&
      friendRelations[bob][alice] == true;
  }
}