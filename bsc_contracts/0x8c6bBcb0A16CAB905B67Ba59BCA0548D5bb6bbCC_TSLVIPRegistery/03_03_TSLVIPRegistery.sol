// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TSLVIPRegistery is Ownable {
    mapping(address => bool) public registered;
    mapping(address => address[]) public inviters;
    mapping(address => address[]) public invited;
    mapping(bytes4 => address) public inviteCodeToAddress;
    uint256 public level = 12;
    uint256 public count;
    bytes4 public devCode;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor() {
        devCode = bytes4(keccak256(abi.encodePacked(msg.sender)));
        inviteCodeToAddress[devCode] = msg.sender;
    }

    function regist(bytes4 inviteCode) external callerIsUser {
        address inviter = inviteCodeToAddress[inviteCode];
        require(inviter != address(0), "invalid code");
        require(!registered[msg.sender], "user already registered");
        require(msg.sender != inviter, "user can not be inviter");
        inviters[msg.sender].push(inviter);
        address[] storage fallBackInviters = inviters[inviter];
        if (fallBackInviters.length == level) {
            fallBackInviters.pop();
        }
        uint256 i;
        if (fallBackInviters.length > 0) {
            for (i = 0; i < fallBackInviters.length; i++) {
                require(msg.sender != fallBackInviters[i],"duplicated inviter");
                inviters[msg.sender].push(fallBackInviters[i]);
            }
        }
        count++;
        invited[inviter].push(msg.sender);
        registered[msg.sender] = true;
    }

    function generateInviteCode() public returns(bytes4) {
        inviteCodeToAddress[bytes4(keccak256(abi.encodePacked(msg.sender)))] = msg.sender;
        return bytes4(keccak256(abi.encodePacked(msg.sender)));
    }
    function getInviteCode(address user) public view returns(bytes4) {
        require(inviteCodeToAddress[bytes4(keccak256(abi.encodePacked(user)))] == user, "unregisted code");
        return bytes4(keccak256(abi.encodePacked(user)));
    }

    function getInviters(address user)
        external
        view
        returns (address[] memory)
    {
        return inviters[user];
    }

    function getInvited(address user) external view returns (address[] memory) {
        return invited[user];
    }

    function setLevel(uint256 level_) public onlyOwner {
        level = level_;
    }

    function setDevCode(address user) public onlyOwner {
        devCode = bytes4(keccak256(abi.encodePacked(user)));
    }
}