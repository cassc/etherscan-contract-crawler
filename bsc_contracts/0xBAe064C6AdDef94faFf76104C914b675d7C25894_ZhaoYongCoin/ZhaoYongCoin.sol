/**
 *Submitted for verification at BscScan.com on 2023-05-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZhaoYongCoin {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public transactionFeeRate; // in basis points (0.05% = 5 basis points)

    mapping(address => uint256) public balanceOf;

    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);

    constructor() {
        name = "ZhaoYong Coin";
        symbol = "ZYC";
        decimals = 18;
        totalSupply = 100000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        transactionFeeRate = 5; // 0.05% = 5 basis points
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        uint256 fee = (value * transactionFeeRate) / 10000;
        uint256 netValue = value - fee;
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += netValue;
        balanceOf[owner] += fee;
        emit Transfer(msg.sender, to, netValue);
        emit Transfer(msg.sender, owner, fee);
        return true;
    }

    function mint(address to, uint256 value) public {
        require(msg.sender == owner, "Only the owner can mint new coins");
        totalSupply += value;
        balanceOf[to] += value;
        emit Mint(to, value);
    }
}