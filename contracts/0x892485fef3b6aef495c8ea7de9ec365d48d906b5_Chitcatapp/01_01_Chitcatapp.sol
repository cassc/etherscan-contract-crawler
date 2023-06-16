//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Chitcatapp {
    struct User {
        string name;
        Friend[] friendlist;
    }

    struct Friend {
        address pubKey;
        string name;
    }

    struct AllUsersStruct {
        string name;
        address account;
    }

    struct Message {
        address sender;
        uint256 timeStamp;
        string message;
    }

    AllUsersStruct[] getAllUsers;

    mapping(address => User) userList;
    mapping(bytes32 => Message[]) allMessages;

    //create Account
    function createAccount(string calldata name) external {
        require(checkUserExists(msg.sender) == false, "User already exists");
        require(bytes(name).length > 0, "User name cannot be empty");

        userList[msg.sender].name = name;
        getAllUsers.push(AllUsersStruct(name, msg.sender));
    }

    //Add Friend
    function addFriend(address friend_key, string calldata name) external {
        require(checkUserExists(friend_key), "User does not exist");
        require(checkUserExists(msg.sender), "create an account first");
        require(msg.sender != friend_key, "User cant add themselves as friend");
        require(
            checkAlreadyFriends(msg.sender, friend_key) == false,
            "Alredy friends"
        );

        _addFriend(msg.sender, friend_key, name);
        _addFriend(friend_key, msg.sender, userList[msg.sender].name);
    }

    //Sends message
    function sendMessage(address friend, string calldata _msg) external {
        require(checkUserExists(friend), "User does not exist");
        require(checkUserExists(msg.sender), "create an account first");
        require(checkAlreadyFriends(msg.sender, friend), "Not friends");

        bytes32 chatCode = _getChatCode(msg.sender, friend);
        Message memory newMsg = Message(msg.sender, block.timestamp, _msg);
        allMessages[chatCode].push(newMsg);
    }

    // adds freind address to friendList
    function _addFriend(
        address user,
        address friend,
        string memory friendName
    ) internal {
        Friend memory newFriend = Friend(friend, friendName);
        userList[user].friendlist.push(newFriend);
    }

    //Read Message
    function readMessage(
        address friend
    ) external view returns (Message[] memory) {
        bytes32 chatCode = _getChatCode(msg.sender, friend);
        return allMessages[chatCode];
    }

    // check if user exist or not
    function checkUserExists(address _user) public view returns (bool) {
        return bytes(userList[_user].name).length > 0;
    }

    // Checks if already friends or not
    function checkAlreadyFriends(
        address user,
        address friend
    ) internal view returns (bool) {
        if (
            userList[user].friendlist.length >
            userList[friend].friendlist.length
        ) {
            address tmp = user;
            user = friend;
            friend = tmp;
        }

        for (uint256 i = 0; i < userList[user].friendlist.length; i++) {
            if (userList[user].friendlist[i].pubKey == friend) return true;
        }
        return false;
    }

    // returns name of user
    function getUserName(address pubKey) external view returns (string memory) {
        require(checkUserExists(pubKey), "User does not exist");
        return userList[pubKey].name;
    }

    // returns friend array
    function getFriendList() external view returns (Friend[] memory) {
        return userList[msg.sender].friendlist;
    }

    // returns chat code
    function _getChatCode(
        address pubKey1,
        address pubKey2
    ) public pure returns (bytes32) {
        if (pubKey1 < pubKey2) {
            return keccak256(abi.encodePacked(pubKey1, pubKey2));
        }
        return keccak256(abi.encodePacked(pubKey2, pubKey1));
    }

    // get all user
    function getAllUsersApp() public view returns (AllUsersStruct[] memory) {
        return getAllUsers;
    }
}