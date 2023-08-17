/**
 *Submitted for verification at Etherscan.io on 2023-08-15
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

contract SLPX is IERC20 {
    string public name = "Stealth Launch Platform";
    string public symbol = "SLPX";
    uint8 public decimals = 18;
    uint256 private _totalSupply = 1_000_000_000 * (10 ** uint256(decimals));

    uint256 public buyTaxPercent = 1;
    uint256 public sellTaxPercent = 1;
    bool public taxesRemoved = true;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        require(buyTaxPercent <= 100 && sellTaxPercent <= 100, "Tax percentage too high.");
        
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function _updateTax(uint256 amount, uint256 taxPercent) internal pure returns (uint256) {
        return amount - (amount * taxPercent / 100);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "Transfer to the zero address");
        
        uint256 finalAmount = amount;
        if (!taxesRemoved) {
            if (recipient == address(this) || recipient == address(0)) {
                finalAmount = _updateTax(amount, sellTaxPercent);
            } else {
                finalAmount = _updateTax(amount, buyTaxPercent);
            }
        }

        require(_balances[msg.sender] >= finalAmount, "Insufficient balance");
        
        _balances[msg.sender] -= finalAmount;
        _balances[recipient] += finalAmount;
        emit Transfer(msg.sender, recipient, finalAmount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        
        uint256 finalAmount = amount;
        if (!taxesRemoved) {
            if (recipient == address(this) || recipient == address(0)) {
                finalAmount = _updateTax(amount, sellTaxPercent);
            } else {
                finalAmount = _updateTax(amount, buyTaxPercent);
            }
        }

        require(_balances[sender] >= finalAmount, "Insufficient balance");
        require(_allowances[sender][msg.sender] >= finalAmount, "Allowance exceeded");

        _balances[sender] -= finalAmount;
        _balances[recipient] += finalAmount;
        _allowances[sender][msg.sender] -= finalAmount;
        emit Transfer(sender, recipient, finalAmount);
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}