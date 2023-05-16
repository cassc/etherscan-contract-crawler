/**
 *Submitted for verification at Etherscan.io on 2023-05-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NoStepOnSnek {
    string public name = "No Step On Snek";
    string public symbol = "SNEK";
    uint256 public totalSupply = 696969696969;
    mapping(address => uint256) balances;
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance.");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
}