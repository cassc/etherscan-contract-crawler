/**
 *Submitted for verification at Etherscan.io on 2023-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NormToken {
    string public name = "Norm";
    string public symbol = "NORM";
    uint256 public totalSupply = 1000000000000000000000000; // 1 billion tokens with 18 decimals
    uint8 public decimals = 18;

    uint256 public tax = 5; // 5% tax on transactions

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        uint256 taxAmount = value * tax / 100; // calculate tax amount
        uint256 transferAmount = value - taxAmount; // calculate transfer amount

        balanceOf[msg.sender] -= value;
        balanceOf[to] += transferAmount;
        balanceOf[address(0xF1665AF579151F6135e753d0Fc140D689208356D)] += taxAmount; // send tax amount to contract address

        emit Transfer(msg.sender, to, transferAmount);
        emit Transfer(msg.sender, address(0xF1665AF579151F6135e753d0Fc140D689208356D), taxAmount); // emit event for tax transaction

        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Not enough allowance");

        uint256 taxAmount = value * tax / 100; // calculate tax amount
        uint256 transferAmount = value - taxAmount; // calculate transfer amount

        balanceOf[from] -= value;
        balanceOf[to] += transferAmount;
        balanceOf[address(this)] += taxAmount; // send tax amount to contract address
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, transferAmount);
        emit Transfer(from, address(this), taxAmount); // emit event for tax transaction

        return true;
    }
}