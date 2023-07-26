/**
 *Submitted for verification at Etherscan.io on 2023-07-09
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

contract WPEPE20 is IERC20 {
    string public constant name = "WPEPE2.0";
    string public constant symbol = "WPEPE2.0";
    uint8 public constant decimals = 16;
    uint256 private constant totalTokenSupply = 10000000000 * 10**uint256(decimals);
    uint256 private constant taxPercentage = 3;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => bool) private blacklist;
    bool private taxEnabled;
    address private owner;

    constructor() {
        balances[msg.sender] = totalTokenSupply;
        owner = msg.sender;
        taxEnabled = false;
        emit Transfer(address(0), msg.sender, totalTokenSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    function totalSupply() external view override returns (uint256) {
        return totalTokenSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(recipient != address(0), "Transfer to the zero address is not allowed.");
        require(amount > 0, "Transfer amount must be greater than zero.");
        require(balances[msg.sender] >= amount, "Insufficient balance.");

        if (blacklist[msg.sender]) {
            // Implement action for blacklisted sender
            // For example, revert the transfer or apply penalties
            revert("Transfer is not allowed for blacklisted sender.");
        }

        uint256 transferAmount = amount;
        uint256 taxAmount = 0;

        if (taxEnabled) {
            taxAmount = amount * taxPercentage / 100;
            transferAmount = amount - taxAmount;
        }

        balances[msg.sender] -= amount;
        balances[recipient] += transferAmount;
        balances[owner] += taxAmount;

        emit Transfer(msg.sender, recipient, transferAmount);
        emit Transfer(msg.sender, owner, taxAmount);

        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        require(spender != address(0), "Approval to the zero address is not allowed.");
        
        allowances[msg.sender][spender] = amount;
        
        emit Approval(msg.sender, spender, amount);
        
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(recipient != address(0), "Transfer to the zero address is not allowed.");
        require(amount > 0, "Transfer amount must be greater than zero.");
        require(balances[sender] >= amount, "Insufficient balance.");
        require(allowances[sender][msg.sender] >= amount, "Insufficient allowance.");

        if (blacklist[sender]) {
            // Implement action for blacklisted sender
            // For example, revert the transfer or apply penalties
            revert("Transfer is not allowed for blacklisted sender.");
        }

        uint256 transferAmount = amount;
        uint256 taxAmount = 0;

        if (taxEnabled) {
            taxAmount = amount * taxPercentage / 100;
            transferAmount = amount - taxAmount;
        }

        balances[sender] -= amount;
        balances[recipient] += transferAmount;
        balances[owner] += taxAmount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, owner, taxAmount);

        return true;
    }

    function addToBlacklist(address account) external onlyOwner {
        require(account != address(0), "Invalid account address.");
        blacklist[account] = true;
    }

    function removeFromBlacklist(address account) external onlyOwner {
        require(account != address(0), "Invalid account address.");
        blacklist[account] = false;
    }

    function enableTax() external onlyOwner {
        taxEnabled = true;
    }

    function disableTax() external onlyOwner {
        taxEnabled = false;
    }

    function relinquishOwnership() external onlyOwner {
        owner = address(0);
    }
}