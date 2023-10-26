/**
 *Submitted for verification at Etherscan.io on 2023-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
/*
Telegram: https://t.me/buffpepetokenportal
Twitter:  https://twitter.com/buffpepetoken
Name:     Buff Pepe
Symbol:   BPEPE
Supply:   420000000000000
Buy Tax:  0%
Sell Tax: 0%
Max W/TX/B/S: No limitations
*/
contract PEPE {
    string private constant _symbol = "PEPE";
    string private constant _name = "Buff Pepe";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply = 10000000000 * 10**uint256(_decimals);
    address private _getDev;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address private _owner;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner() {
        require(msg.sender == _owner, "Sorry, only owner calls this");
        _;
    }
    constructor() {
        _owner = msg.sender;
        _getDev = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function getBuffPepeDev() public view returns (address) {
        return _getDev;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function name() public pure returns (string memory) {
        return _name;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "You cannot do this");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "You cannot do this");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
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