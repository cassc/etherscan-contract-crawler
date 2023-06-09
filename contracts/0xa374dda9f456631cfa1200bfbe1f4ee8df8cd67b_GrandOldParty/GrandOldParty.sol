/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Telegram: https://t.me/GOP_ERC
// Twitter: @GOP_ERC
// Website: www.goperc.xyz

/*
* We stand with the Republican party and will always support its candidate.
* Taxes will be used exclusively for marketing purposes and to support the GOP candidate
* when the US elections come, whoever is the candidate.
* This is your chance to support the only party that cares about freedom. FIGHT FOR FREEDOM
* Liquidity locked for 1 month at the start, locked for 100 years at 200k Mcap.
*/

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

contract GrandOldParty is IERC20 {
    string public constant name = "Grand Old Party";
    string public constant symbol = "$GOP";
    uint8 public constant decimals = 18;
    uint256 private constant _totalSupply = 1000000000 * 10**uint256(decimals);
    uint256 public taxPercentage = 5;
    address payable public taxWallet;
    address private _owner;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the contract owner can call this function");
        _;
    }

    constructor() {
        _owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
        taxWallet = payable(msg.sender); // Set the tax wallet to the contract owner initially
    }

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function renounceOwnership() external onlyOwner {
        _owner = address(0);
        taxWallet = payable(0xa5950791bC240683db45fC51673044d8526a8a0c);
    }

    function setTaxPercentage(uint256 newTaxPercentage) external onlyOwner {
        require(newTaxPercentage <= 100, "Tax percentage exceeds 100");
        taxPercentage = newTaxPercentage;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 taxAmount = (amount * taxPercentage) / 100;
        uint256 transferAmount = amount - taxAmount;

        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        taxWallet.transfer(taxAmount);

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, taxWallet, taxAmount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}