/**
 *Submitted for verification at BscScan.com on 2023-02-25
*/

// SPDX-License-Identifier: UNLISCENSED
pragma solidity ^0.8.4;

contract Yonobit {
    string public name = "Yonobit";
    string public symbol = "YONO";
    uint256 public totalSupply = 200000 ether;
    uint8 public decimals = 18;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public locked;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Lock(address indexed account, uint256 amount);
    event Unlock(address indexed account, uint256 amount);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(!locked[msg.sender], "Account is locked");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(!locked[from], "Account is locked");
        require(value <= allowance[from][msg.sender], "Allowance exceeded");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function lockSupply(uint256 amount) public returns (bool success) {
        require(amount <= balanceOf[msg.sender], "Insufficient balance");
        require(amount <= totalSupply - 100000 ether, "Amount exceeds unlockable supply");
        balanceOf[msg.sender] -= amount;
        locked[msg.sender] = true;
        emit Lock(msg.sender, amount);
        return true;
    }

    function unlockSupply(address to, uint256 amount) public returns (bool success) {
        require(msg.sender == tx.origin, "Unlocking must be initiated by an EOA");
        require(locked[msg.sender], "Account is not locked");
        balanceOf[to] += amount;
        locked[msg.sender] = false;
        emit Unlock(msg.sender, amount);
        return true;
    }
}