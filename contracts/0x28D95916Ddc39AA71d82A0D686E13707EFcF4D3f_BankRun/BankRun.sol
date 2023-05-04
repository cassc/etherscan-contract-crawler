/**
 *Submitted for verification at Etherscan.io on 2023-05-03
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

contract BankRun {
    string public name = "Bank Run";
    string public symbol = "BANKRUN";
    uint256 public totalSupply = 10000000000 * 10**18;
    uint8 public decimals = 18;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    uint256 public maxWalletAmount = totalSupply * 2 / 100;
    uint256 public maxTransactionAmount = totalSupply * 2 / 100;
    
    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address to, uint256 amount) public {
        require(amount <= balanceOf[msg.sender], "Insufficient balance");
        require(amount <= maxTransactionAmount, "Amount exceeds max transaction limit");
        require(balanceOf[to] + amount <= maxWalletAmount, "Wallet balance exceeds max limit");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(amount <= balanceOf[from], "Insufficient balance");
        require(amount <= allowance[from][msg.sender], "Amount exceeds allowance");
        require(amount <= maxTransactionAmount, "Amount exceeds max transaction limit");
        require(balanceOf[to] + amount <= maxWalletAmount, "Wallet balance exceeds max limit");
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        
        return true;
    }
}