/**
 *Submitted for verification at Etherscan.io on 2023-07-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Safe Math Library
library SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: Addition overflow");
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: Subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: Multiplication overflow");
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: Division by zero");
        uint256 c = a / b;
        return c;
    }
}

// ERC20 Token Interface
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

// Actual Token Contract
contract MyCustomToken is IERC20 {
    using SafeMath for uint256;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 private _totalSupply;

    uint256 public sellTaxRate; // Tax rate for selling tokens (in basis points, 1 basis point = 0.01%)
    uint256 public buyTaxRate; // Tax rate for buying tokens (in basis points, 1 basis point = 0.01%)

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        symbol = "DCKSCM";
        name = "DuckScam";
        decimals = 2;
        _totalSupply = 100000 * 10 ** uint256(decimals);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        // Set default tax rates (100 basis points = 1%)
        sellTaxRate = 100; // 1% tax on selling tokens
        buyTaxRate = 50; // 0.5% tax on buying tokens
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view override returns (uint256 balance) {
        return _balances[tokenOwner];
    }

    function transfer(address to, uint256 amount) public override returns (bool success) {
        uint256 taxedAmount = applyTax(amount, sellTaxRate);
        _balances[msg.sender] = _balances[msg.sender].safeSub(amount);
        _balances[to] = _balances[to].safeAdd(taxedAmount);
        emit Transfer(msg.sender, to, taxedAmount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool success) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool success) {
        uint256 taxedAmount = applyTax(amount, sellTaxRate);
        _balances[from] = _balances[from].safeSub(amount);
        _allowances[from][msg.sender] = _allowances[from][msg.sender].safeSub(amount);
        _balances[to] = _balances[to].safeAdd(taxedAmount);
        emit Transfer(from, to, taxedAmount);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view override returns (uint256 remaining) {
        return _allowances[tokenOwner][spender];
    }

    // Apply tax on token amount based on the given tax rate (in basis points)
    function applyTax(uint256 amount, uint256 taxRate) internal pure returns (uint256) {
        uint256 taxAmount = amount.safeMul(taxRate).safeDiv(10000); // Calculate the tax amount (amount * taxRate / 10000)
        return amount.safeSub(taxAmount); // Subtract the tax amount from the original amount
    }

    // Set sell tax rate (in basis points)
    function setSellTaxRate(uint256 rate) external {
        require(rate <= 10000, "Invalid tax rate"); // Ensure the tax rate is not greater than 100 basis points (1%)
        sellTaxRate = rate;
    }

    // Set buy tax rate (in basis points)
    function setBuyTaxRate(uint256 rate) external {
        require(rate <= 10000, "Invalid tax rate"); // Ensure the tax rate is not greater than 100 basis points (1%)
        buyTaxRate = rate;
    }
}