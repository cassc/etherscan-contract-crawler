/**
 *Submitted for verification at Etherscan.io on 2023-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vitalikbag {
    string public name = "Vitalikbag";
    string public symbol = "VBAG";
    uint256 public totalSupply = 16_180_000_000_000 * 10**18; // 16.180 trillion tokens
    uint8 public decimals = 18;

    uint256 public maxTransactionAmount = totalSupply / 100; // 1% of total supply

    uint256 private baseUnit; // Token's base unit value

    address public owner;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        baseUnit = 10**decimals;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    modifier antiWhale(uint256 amount) {
        require(amount <= maxTransactionAmount, "Exceeds maximum transaction amount");
        _;
    }

    function transfer(address to, uint256 value) external antiWhale(value) returns (bool) {
        uint256 transferAmount = value * baseUnit;
        require(balanceOf[msg.sender] >= transferAmount, "Insufficient balance");

        balanceOf[msg.sender] -= transferAmount;
        balanceOf[to] += transferAmount;

        emit Transfer(msg.sender, to, transferAmount);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external antiWhale(value) returns (bool) {
        uint256 transferAmount = value * baseUnit;
        require(balanceOf[from] >= transferAmount, "Insufficient balance");
        require(allowance[from][msg.sender] >= transferAmount, "Not enough allowance");

        balanceOf[from] -= transferAmount;
        balanceOf[to] += transferAmount;
        allowance[from][msg.sender] -= transferAmount;

        emit Transfer(from, to, transferAmount);
        return true;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}