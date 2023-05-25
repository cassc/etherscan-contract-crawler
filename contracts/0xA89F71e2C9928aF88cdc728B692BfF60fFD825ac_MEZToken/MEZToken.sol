/**
 *Submitted for verification at Etherscan.io on 2023-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MEZToken {
    string public name = "Memezy";
    string public symbol = "MEZ";
    uint256 public totalSupply = 1000000000000 * 10**18; // 1,000,000,000,000 MEZ
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address private developmentAddress = 0xB608A3052F425675a8B00323202A406EEfd1694b;
    uint256 private developmentPercentage = 35;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply * (100 - developmentPercentage) / 100;
        balanceOf[developmentAddress] = totalSupply * developmentPercentage / 100;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "MEZ: Invalid recipient");
        require(value > 0, "MEZ: Invalid amount");

        uint256 senderBalance = balanceOf[msg.sender];
        require(senderBalance >= value, "MEZ: Insufficient balance");

        balanceOf[msg.sender] = senderBalance - value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0), "MEZ: Invalid spender");

        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(from != address(0), "MEZ: Invalid sender");
        require(to != address(0), "MEZ: Invalid recipient");
        require(value > 0, "MEZ: Invalid amount");

        uint256 senderBalance = balanceOf[from];
        require(senderBalance >= value, "MEZ: Insufficient balance");

        uint256 allowedAmount = allowance[from][msg.sender];
        require(allowedAmount >= value, "MEZ: Exceeds allowance");

        balanceOf[from] = senderBalance - value;
        balanceOf[to] += value;
        allowance[from][msg.sender] = allowedAmount - value;

        emit Transfer(from, to, value);
        return true;
    }
}