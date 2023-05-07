/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

contract Pepenoot {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 69000000000 * 10 ** 18;
    string public name = "Pepenoot";
    string public symbol = "PNOOT";
    uint public decimals = 18;
    uint public burnRate = 420; // 4.20%
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed from, uint256 value);
  
    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns (uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns (bool) {
        uint burnAmount = value * burnRate / 10000; // Calculate burn amount
        uint transferAmount = value - burnAmount; // Calculate transfer amount
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += transferAmount;
        balances[msg.sender] -= value;
        totalSupply -= burnAmount; // Update total supply
        emit Transfer(msg.sender, to, transferAmount);
        emit Burn(msg.sender, burnAmount);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns (bool) {
        uint burnAmount = value * burnRate / 10000; // Calculate burn amount
        uint transferAmount = value - burnAmount; // Calculate transfer amount
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += transferAmount;
        balances[from] -= value;
        totalSupply -= burnAmount; // Update total supply
        emit Transfer(from, to, transferAmount);
        emit Burn(from, burnAmount);
        return true;
    }

    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}