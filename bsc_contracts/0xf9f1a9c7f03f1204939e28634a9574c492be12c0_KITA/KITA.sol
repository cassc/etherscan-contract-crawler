/**
 *Submitted for verification at BscScan.com on 2023-05-23
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

contract KITA is IERC20 {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public exemptWallets;
    
    address private constant pancakeSwapRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    address private constant charityWallet = 0xA67dE2b8c36848802b711D551c23935d987ABBEd;
    address private constant marketingWallet = 0x9488cA8E59D7D68a63babB98Cb722AA7fcda3dfc;
    
    uint256 private constant taxPercentage = 8;
    uint256 private constant liquidityTaxPercentage = 5;
    uint256 private constant burnTaxPercentage = 1;
    uint256 private constant charityTaxPercentage = 1;
    uint256 private constant marketingTaxPercentage = 1;
    
    constructor() {
        name = "KITA INU";
        symbol = "KITA";
        decimals = 18;
        _totalSupply = 1_000_000_000_000_000_000_000_000_000; // 1 quadrillion
        _balances[msg.sender] = _totalSupply;
        exemptWallets[msg.sender] = true; // Deployer wallet is exempt from taxes
        exemptWallets[charityWallet] = true;
        exemptWallets[marketingWallet] = true;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        uint256 taxAmount = (amount * taxPercentage) / 100;
        uint256 tokensToTransfer = amount - taxAmount;
        
        _balances[sender] -= amount;
        _balances[recipient] += tokensToTransfer;
        emit Transfer(sender, recipient, tokensToTransfer);
        
        if (taxAmount > 0) {
            _handleTax(sender, taxAmount);
        }
    }
    
    function _handleTax(address sender, uint256 taxAmount) internal {
        uint256 burnTax = (taxAmount * burnTaxPercentage) / taxPercentage;
        uint256 charityTax = (taxAmount * charityTaxPercentage) / taxPercentage;
        uint256 marketingTax = (taxAmount * marketingTaxPercentage) / taxPercentage;
        
        if (burnTax > 0) {
            _transferToAddress(sender, burnAddress, burnTax);
        }
        if (charityTax > 0) {
            _transferToAddress(sender, charityWallet, charityTax);
        }
        if (marketingTax > 0) {
            _transferToAddress(sender, marketingWallet, marketingTax);
        }
        
        uint256 liquidityTax = taxAmount - burnTax - charityTax - marketingTax;
        if (liquidityTax > 0) {
            _transferToAddress(sender, pancakeSwapRouter, liquidityTax);
        }
    }
    
    function _transferToAddress(address sender, address recipient, uint256 amount) internal {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}