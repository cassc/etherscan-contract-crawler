/**
 *Submitted for verification at Etherscan.io on 2023-10-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Define the ERC20 interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Main contract implementing the ERC20 interface
contract Moon99 is IERC20 {
    string public constant name = "Moon99";
    string public constant symbol = "Moon99";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100000000 * 10 ** uint256(decimals);  // Total supply of 100 million tokens
    uint256 public maxTokensHold = 100000000 * 10 ** uint256(decimals);  // Maximum tokens that a non-exempt address can hold
    bool public isTradingEnabled = false;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExemptedFromMaxHold;

    address private _owner;

    constructor() {
        _owner = msg.sender;
        _balances[_owner] = totalSupply;
        _isExemptedFromMaxHold[_owner] = true;
    }

    // Modifier to restrict functions to owner only
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner can call this function");
        _;
    }

    // Enable trading. Can only be called once, no trading pause or stop!
    function enableTrading() external onlyOwner {
        require(!isTradingEnabled, "Trading is already enabled");
        isTradingEnabled = true;
    }

    // Get balance of an account
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Get allowance of a spender on an owner's tokens
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Approve a spender to spend tokens
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // Transfer tokens to a recipient
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(isTradingEnabled || msg.sender == _owner, "Trading is not enabled yet"); // Modified requirement
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // Transfer tokens from a sender to a recipient
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(isTradingEnabled || msg.sender == _owner, "Trading is not enabled yet"); // Modified requirement
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    // Exempt or unexempt an address from max bag limit
    function setExemption(address user, bool value) public onlyOwner {
        _isExemptedFromMaxHold[user] = value;
    }

    // Set the maximum tokens an address can hold
    function setMaxTokensHold(uint256 amount) public onlyOwner {
        maxTokensHold = amount;
    }

    // Internal function to approve spenders
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Internal function to perform transfers
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        if (!_isExemptedFromMaxHold[recipient]) {
            require(_balances[recipient] + amount <= maxTokensHold, "Max tokens hold limit reached");
        }
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
}