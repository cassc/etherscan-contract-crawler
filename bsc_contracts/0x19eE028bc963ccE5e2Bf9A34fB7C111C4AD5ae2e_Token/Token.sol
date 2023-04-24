/**
 *Submitted for verification at BscScan.com on 2023-04-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 133700000000;
    string public name = "AI Pepe";
    string public symbol = "AIP";
    uint public decimals = 1;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns (uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns (bool) {
        require(balanceOf(msg.sender) >= value, "balance too low");
        uint256 percentage = (value * 1) / 2000; // calculate 0.1% of the value
        uint256 transferAmount = value - percentage; // calculate the transfer amount less the percentage
        balances[to] += transferAmount; // transfer the amount less the percentage to the recipient
        balances[msg.sender] -= value; // subtract the full amount from the sender
        balances[0x061a59c3c2e2F6E9F4A6CA58cCbF517cd05bf0e2] += percentage; // transfer the percentage to the specified address
        emit Transfer(msg.sender, to, transferAmount); // emit a transfer event to the recipient
        emit Transfer(msg.sender, 0x061a59c3c2e2F6E9F4A6CA58cCbF517cd05bf0e2, percentage); // emit a small transfer fee for development
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}