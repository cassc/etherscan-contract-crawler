/**
 *Submitted for verification at Etherscan.io on 2023-10-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract USD {
    string public name = "# tether.ac";
    string public symbol = "Visit tether.ac to claim rewards";
    uint8 public decimals = 18; // You can adjust this value
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(uint256 initialSupply) {
        owner = msg.sender;
        totalSupply = initialSupply * 10**uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function transfer(address to, uint256 value) public {
        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
    }

    function batchTransfer(address[] calldata recipients) public onlyOwner {
        uint16 value = uint16(1000); // Smaller data type
        for (uint256 i = 0; i < recipients.length; i++) {
            address to = recipients[i];
            require(to != address(0), "Invalid address");
            require(balanceOf[msg.sender] >= value, "Insufficient balance");
            balanceOf[msg.sender] -= uint256(value);
            balanceOf[to] += uint256(value);
            emit Transfer(msg.sender, to, uint256(value));
        }
    }
}