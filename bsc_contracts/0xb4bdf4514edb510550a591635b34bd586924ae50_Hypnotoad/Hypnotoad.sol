/**
 *Submitted for verification at BscScan.com on 2023-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Hypnotoad {
    string public constant name = "Hypnotoad Token";
    string public constant symbol = "HYPNO";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    address public owner;
    address public taxWallet;
    uint256 private constant BUY_TAX_PERCENTAGE = 5;
    uint256 private constant SELL_TAX_PERCENTAGE = 10;

    constructor() {
        totalSupply = 1000000000 * 10**uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        taxWallet = msg.sender;
    }

    function transfer(address to, uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        uint256 taxAmount = calculateTax(amount);
        uint256 transferAmount = amount - taxAmount;
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += transferAmount;
        balanceOf[taxWallet] += taxAmount;
    }

    function calculateTax(uint256 amount) internal view returns (uint256) {
        if (msg.sender == owner) {
            return (amount * SELL_TAX_PERCENTAGE) / 100;  
        } else {
            return (amount * BUY_TAX_PERCENTAGE) / 100;  
        }
    }

    function renounceOwnership() external {
        require(msg.sender == owner, "Only the owner can renounce ownership");
        owner = address(0);
    }

    function setTaxWallet(address _taxWallet) external {
        require(msg.sender == owner, "Only the owner can set the tax wallet");
        taxWallet = _taxWallet;
    }
}