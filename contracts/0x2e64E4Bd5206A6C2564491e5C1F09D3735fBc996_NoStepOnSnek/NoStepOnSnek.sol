/**
 *Submitted for verification at Etherscan.io on 2023-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract NoStepOnSnek is IERC20 {
    string public name = "No Step On Snek";
    string public symbol = "SNEK";
    uint256 public totalSupply = 696969696969696969696969696969696; 
    uint8 public decimals = 18;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(amount > 0, "Amount must be greater than zero.");
        require(amount <= balances[msg.sender], "Insufficient balance.");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(amount > 0, "Amount must be greater than zero.");
        require(amount <= balances[sender], "Insufficient balance.");
        require(amount <= allowances[sender][msg.sender], "Insufficient allowance.");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowances[sender][msg.sender] - amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "Invalid spender address.");
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(recipient != address(0), "Invalid recipient address.");
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Invalid owner address.");
        require(spender != address(0), "Invalid spender address.");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}