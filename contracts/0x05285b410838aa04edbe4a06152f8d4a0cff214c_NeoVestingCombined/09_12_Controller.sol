// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Controller is Ownable {
    mapping(address => bool) public adminList;

    function setAdmin(address user_, bool status_) public onlyOwner {
        adminList[user_] = status_;
    }

    modifier onlyAdmin(){
        require(adminList[msg.sender], "Controller: Msg sender is not the admin");
        _;
    }
}