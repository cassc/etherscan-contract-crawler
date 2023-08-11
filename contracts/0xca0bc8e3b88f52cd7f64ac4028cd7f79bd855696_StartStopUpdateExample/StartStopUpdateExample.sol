/**
 *Submitted for verification at Etherscan.io on 2023-07-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

contract StartStopUpdateExample {

    address public owner;
    bool public paused;
    address public manager;
    constructor() {
        owner = msg.sender;
    }

    function sendMoney() public payable {

    }

    function setManager(address _manager) public {
        require(msg.sender == owner, "You are not the owner");
        manager = _manager;
    }

    function setPaused(bool _paused) public {
        require(msg.sender == owner || msg.sender == manager , "You are not allowed");
        paused = _paused;
    }

    function withdrawAllMoney(address payable _to) public {
        require(owner == msg.sender, "You cannot withdraw.");
        require(paused == false, "Contract Paused");
        _to.transfer(address(this).balance);
    }
}