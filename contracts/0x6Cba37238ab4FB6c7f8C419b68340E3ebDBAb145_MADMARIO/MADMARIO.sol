/**
 *Submitted for verification at Etherscan.io on 2023-05-19
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-19
*/
// MAD MARIO SOCIAL MEDIA 
//https://t.me/MADMARIOETH
//https://instagram.com/madmarioerc?igshid=MzRlODBiNWFlZA==
//https://twitter.com/MADMARIO_ETH
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

contract MADMARIO is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _blacklisted;
    address private _uniswapRouterAddress;
    uint256 public taxPercentage;
    address private _taxWallet;

    constructor() {
        name = "MAD MARIO";
        symbol = "MMARIO";
        decimals = 18;
        _totalSupply = 100000000 * 10**decimals;
        _balances[msg.sender] = _totalSupply;
        _uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap router address
        taxPercentage = 3;
        _taxWallet = 0x7593d8A98a61D160D5cab65081C417094f541753; // Tax wallet address
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= _balances[msg.sender], "ERC20: transfer amount exceeds balance");
        require(!_blacklisted[msg.sender], "ERC20: sender is blacklisted");
        require(!_blacklisted[recipient], "ERC20: recipient is blacklisted");
        
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= _balances[sender], "ERC20: transfer amount exceeds balance");
        require(amount <= _allowances[sender][msg.sender], "ERC20: transfer amount exceeds allowance");
        require(!_blacklisted[sender], "ERC20: sender is blacklisted");
        require(!_blacklisted[recipient], "ERC20: recipient is blacklisted");

        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }
    
    function blacklistAddress(address wallet) external onlyOwner {
        _blacklisted[wallet] = true;
    }
    
    function unblacklistAddress(address wallet) external onlyOwner {
        _blacklisted[wallet] = false;
    }
    
    function setTaxPercentage(uint256 percentage) external onlyOwner {
        require(percentage <= 100, "ERC20: tax percentage must be between 0 and 100");
        taxPercentage = percentage;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= _balances[sender], "ERC20: transfer amount exceeds balance");

        uint256 taxAmount = (amount * taxPercentage) / 100;
        uint256 afterTaxAmount = amount - taxAmount;
        require(afterTaxAmount > 0, "ERC20: after-tax amount should be greater than zero");

        _balances[sender] -= amount;
        _balances[recipient] += afterTaxAmount;
        _balances[_taxWallet] += taxAmount; // Send the tax amount to the specified tax wallet
        emit Transfer(sender, recipient, afterTaxAmount);
        emit Transfer(sender, _taxWallet, taxAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    modifier onlyOwner() {
        require(msg.sender == getOwner(), "ERC20: caller is not the owner");
        _;
    }

    function getOwner() public view returns (address) {
        return address(this);
    }
}