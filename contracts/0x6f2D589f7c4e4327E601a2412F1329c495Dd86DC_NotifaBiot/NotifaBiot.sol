/**
 *Submitted for verification at Etherscan.io on 2023-10-24
*/

/**

Telegram: https://t.me/notifaeth

WE HAVE JUST GONE LIVE!!!!!

This is just a marketing CA. 
Official Contract Address: 0x4ed5db043275066298b584500ee59e5a7e1e57ac 


*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract NotifaBiot {
    string public constant name = "NotifaBot";
    string public constant symbol = "NOTIFA";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 990000000000 * 10**uint256(decimals);

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[sender], "Insufficient balance");
        require(amount <= allowances[sender][msg.sender], "Insufficient allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowances[sender][msg.sender] - amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}