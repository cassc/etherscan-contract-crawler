/**
 *Submitted for verification at BscScan.com on 2023-05-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Peace {
    string public constant name = "Peace";
    string public constant symbol = "PEA";
    uint8 public constant decimals = 6;
    uint256 public totalSupply;
    address payable public marketingWallet;

    uint256 public constant tax = 5 * (10 ** 15); // 0.005 BNB

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address payable _marketingWallet) {
        totalSupply = 500000000 * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply;
        marketingWallet = _marketingWallet;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public payable returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(msg.value >= tax, "Insufficient BNB to cover the transaction tax");

        marketingWallet.transfer(msg.value);

        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function transferFrom(address sender, address recipient, uint256 amount) public payable returns (bool) {
        require(balances[sender] >= amount, "Insufficient balance");
        require(allowances[sender][msg.sender] >= amount, "Insufficient allowance");
        require(msg.value >= tax, "Insufficient BNB to cover the transaction tax");

        marketingWallet.transfer(msg.value);

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}