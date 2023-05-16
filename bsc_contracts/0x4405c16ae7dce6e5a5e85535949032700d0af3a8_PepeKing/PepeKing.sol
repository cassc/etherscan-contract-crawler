/**
 *Submitted for verification at BscScan.com on 2023-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PepeKing { //0xA6EaC35e213dbe2d8200E77B39D5cCf70B8335F8
    address public owner;
    uint256 public balance;
    
    constructor() {
        owner = msg.sender; // store information who deployed contract
    }
    
    receive() payable external {
        balance += msg.value; // keep track of balance (in WEI)
    }
    
    
    function withdraw(uint amount, address payable destAddr) public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(amount <= balance, "Insufficient funds");
        
        destAddr.transfer(amount); // send funds to given address
        balance -= amount;
    }
}