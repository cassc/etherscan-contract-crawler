/**
 *Submitted for verification at BscScan.com on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MOOVE {
    string public name = "MOOVE CURRENCY";
    string public symbol = "MOOVE";
    uint256 public totalSupply = 400000000 * 10**18; // Total supply with 18 decimal places
    uint8 public decimals = 18;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    
    address public contractOwner;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor() {
        contractOwner = 0xD5a8ff640a8C825A06bC0E72a3f8c494F15c0635;
        balances[contractOwner] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can call this function");
        _;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(balances[sender] >= amount, "Insufficient balance");
        require(allowances[sender][msg.sender] >= amount, "Insufficient allowance");

        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowances[sender][msg.sender] - amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return allowances[tokenOwner][spender];
    }

    function increaseAllowance(address spender, uint256 addedAmount) public returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender] + addedAmount);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedAmount) public returns (bool) {
        require(allowances[msg.sender][spender] >= subtractedAmount, "Decreased allowance below zero");
        _approve(msg.sender, spender, allowances[msg.sender][spender] - subtractedAmount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}