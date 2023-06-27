/**
 *Submitted for verification at Etherscan.io on 2023-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CHOCHToken is IERC20 {
    string public name = "CHOCH";
    string public symbol = "CHOCH";
    uint256 public totalSupply = 100000000000 * 10**18; // 100 billion tokens with 18 decimal places
    uint8 public decimals = 18;
    uint256 public sellTaxPercentage = 3;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    address private contractOwner;

    constructor() {
        contractOwner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can call this function");
        _;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(recipient != address(0), "Cannot transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(sender != address(0), "Cannot transfer from the zero address");
        require(recipient != address(0), "Cannot transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balances[sender], "Insufficient balance");
        require(amount <= allowances[sender][msg.sender], "Insufficient allowance");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        require(spender != address(0), "Cannot approve to the zero address");

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address ownerAddress, address spender) external view override returns (uint256) {
        return allowances[ownerAddress][spender];
    }

    function setSellTaxPercentage(uint256 percentage) external onlyOwner {
        require(percentage <= 100, "Tax percentage cannot exceed 100");
        sellTaxPercentage = percentage;
    }

    function sellTokens(uint256 amount) external returns (bool) {
        require(amount > 0, "Sell amount must be greater than zero");
        require(amount <= balances[msg.sender], "Insufficient balance");

        uint256 taxAmount = (amount * sellTaxPercentage) / 100;
        uint256 transferAmount = amount - taxAmount;

        balances[msg.sender] -= amount;
        balances[contractOwner] += taxAmount;
        balances[address(0)] += transferAmount;

        emit Transfer(msg.sender, address(0), transferAmount);
        emit Transfer(msg.sender, contractOwner, taxAmount);
        return true;
    }
}