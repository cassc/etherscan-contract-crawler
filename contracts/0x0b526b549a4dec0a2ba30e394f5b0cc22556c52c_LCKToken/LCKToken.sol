/**
 *Submitted for verification at Etherscan.io on 2023-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LCKToken {
    string public name;
    string public symbol;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        name = "LCK";
        symbol = "LCK";
        _totalSupply = 50000000000000000000000000000; 
        _balanceOf[msg.sender] = _totalSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balanceOf[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(_balanceOf[msg.sender] >= amount, "Insufficient balance");

        _balanceOf[msg.sender] -= amount;
        _balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowance[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(_balanceOf[sender] >= amount, "Insufficient balance");
        require(_allowance[sender][msg.sender] >= amount, "Insufficient allowance");

        _balanceOf[sender] -= amount;
        _balanceOf[recipient] += amount;
        _allowance[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }
}