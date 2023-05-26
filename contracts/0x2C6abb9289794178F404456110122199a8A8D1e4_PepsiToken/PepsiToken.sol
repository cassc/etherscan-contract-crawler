/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract PepsiToken {
    string public name = "PepsiToken";
    string public symbol = "PEPSI";
    uint256 public totalSupply = 900000000000 * 10**18; // Total supply with 18 decimal places
    uint8 public decimals = 18; // The number of decimals in the token
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    uint256 public buySellTax = 1; // 1% buy/sell tax
    
    address public owner;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event BuySellTaxUpdated(uint256 oldTax, uint256 newTax);
    
    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }
    
    function _transfer(address from, address to, uint256 value) internal {
        uint256 tax = value * buySellTax / 100;
        require(tax <= balanceOf[owner], "Insufficient contract balance for tax");
        balanceOf[from] -= value;
        balanceOf[owner] += tax;
        balanceOf[to] += value - tax;
        emit Transfer(from, to, value);
        emit Transfer(from, owner, tax);
    }
    
    function updateBuySellTax(uint256 newTax) public {
        require(msg.sender == owner, "Only owner can update tax");
        require(newTax <= 99, "Tax can't be more than 100%");
        emit BuySellTaxUpdated(buySellTax, newTax);
        buySellTax = newTax;
    }
}