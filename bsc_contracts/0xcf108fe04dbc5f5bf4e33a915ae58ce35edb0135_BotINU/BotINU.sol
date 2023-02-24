/**
 *Submitted for verification at BscScan.com on 2023-02-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract BotINU {
    string public name = "Bot Inu";
    string public symbol = "BOT";
    uint256 public totalSupply = 69420 * 10**18;
    uint8 public decimals = 18;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    address public stakingAddress = 0xf5B47CaAC5c5e0EDd51224eB95e07Ba0857D323b;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balances[stakingAddress] = totalSupply;
        emit Transfer(address(0), stakingAddress, totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "SHITNU: transfer to the zero address");
        require(amount <= balances[msg.sender], "SHITNU: transfer amount exceeds balance");
        
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "SHITNU: transfer to the zero address");
        require(amount <= balances[sender], "SHITNU: transfer amount exceeds balance");
        require(amount <= allowance[sender][msg.sender], "SHITNU: transfer amount exceeds allowance");
        
        balances[sender] -= amount;
        balances[recipient] += amount;
        allowance[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        
        return true;
    }
    
    function burn(uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "SHITNU: burn amount exceeds balance");
        
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
        
        return true;
    }
    
    function burnFrom(address account, uint256 amount) public returns (bool) {
        require(amount <= balances[account], "SHITNU: burn amount exceeds balance");
        require(amount <= allowance[account][msg.sender], "SHITNU: burn amount exceeds allowance");
        
        balances[account] -= amount;
        totalSupply -= amount;
        allowance[account][msg.sender] -= amount;
        emit Transfer(account, address(0), amount);
        
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        allowance[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowance[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "SHITNU: decreased allowance below zero");
        
        allowance[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        
        return true;
    }
}