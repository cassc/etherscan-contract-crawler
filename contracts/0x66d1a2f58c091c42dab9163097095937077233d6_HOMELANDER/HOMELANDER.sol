/**
 *Submitted for verification at Etherscan.io on 2023-10-14
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

contract HOMELANDER is IERC20 {
    string public constant name = "HOMELANDER";
    string public constant symbol = "HOLDR";
    uint8 public constant decimals = 18;
    uint256 private constant _totalSupply = 1000000000 * 10**uint256(decimals);
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address private _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; 
    uint256 private constant _feePercentage = 2; 

    constructor() {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = amount * _feePercentage / 100;
        _balances[msg.sender] -= amount;
        _balances[_router] += fee;
        _balances[recipient] += amount - fee;
        emit Transfer(msg.sender, _router, fee);
        emit Transfer(msg.sender, recipient, amount - fee);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = amount * _feePercentage / 100;
        _balances[sender] -= amount;
        _balances[_router] += fee;
        _balances[recipient] += amount - fee;
        _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, _router, fee);
        emit Transfer(sender, recipient, amount - fee);
        return true;
    }
}