/**
 *Submitted for verification at Etherscan.io on 2023-05-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MIND {
    string public constant name = "MIND";
    string public constant symbol = "MIND";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 1e12 * 10**decimals;
    address public contractOwner;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor() {
        contractOwner = msg.sender;
        _balances[msg.sender] = totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function getAllowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "MIND: transfer from the zero address");
        require(recipient != address(0), "MIND: transfer to the zero address");
        require(amount > 0, "MIND: transfer amount must be greater than zero");
        
        uint256 tax = amount * 5 / 100;
        uint256 transferAmount = amount - tax;
        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[contractOwner] += tax;
        
        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, contractOwner, tax);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "MIND: approve from the zero address");
        require(spender != address(0), "MIND: approve to the zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function burn(uint256 amount) public {
        require(amount > 0, "MIND: burn amount must be greater than zero");
        require(amount <= _balances[msg.sender], "MIND: burn amount exceeds balance");
        
        _balances[msg.sender] -= amount;
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }
}