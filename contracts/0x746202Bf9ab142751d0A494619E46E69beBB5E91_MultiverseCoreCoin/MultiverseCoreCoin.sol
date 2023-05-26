/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiverseCoreCoin {
    string public constant name = "Multiverse Core";
    string public constant symbol = "MC";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 300_000_000 * (10 ** uint256(decimals));

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public taxWallet;
    uint256 public taxRate;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        taxWallet = 0xEa76C7E7C5D0e8F0E7F4537A3f2eC8Ed63C6f671;
        taxRate = 2; // 0.02%
    }

    function calculateTaxAmount(uint256 value) internal view returns (uint256) {
        return (value * taxRate) / 10_000; // Calculate tax amount based on tax rate
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "Invalid recipient address");
        require(value > 0, "Invalid transfer amount");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        uint256 taxAmount = calculateTaxAmount(value);
        uint256 transferAmount = value - taxAmount;

        balanceOf[msg.sender] -= value;
        balanceOf[to] += transferAmount;
        balanceOf[taxWallet] += taxAmount;

        emit Transfer(msg.sender, to, transferAmount);
        emit Transfer(msg.sender, taxWallet, taxAmount);

        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(from != address(0), "Invalid sender address");
        require(to != address(0), "Invalid recipient address");
        require(value > 0, "Invalid transfer amount");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");

        uint256 taxAmount = calculateTaxAmount(value);
        uint256 transferAmount = value - taxAmount;

        balanceOf[from] -= value;
        balanceOf[to] += transferAmount;
        balanceOf[taxWallet] += taxAmount;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, transferAmount);
        emit Transfer(from, taxWallet, taxAmount);

        return true;
    }
}