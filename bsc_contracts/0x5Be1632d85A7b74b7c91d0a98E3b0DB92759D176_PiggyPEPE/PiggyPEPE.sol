/**
 *Submitted for verification at BscScan.com on 2023-05-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PiggyPEPE {
    string private _name = "PiggyPEPE";
    string private _symbol = "PPEPE";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 420690 * 10 ** 9 * 10 ** uint256(_decimals);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address private _owner;
    address private _marketingWallet = 0x5ef54883e332eEF6Cb17F268F3bB24D7A69AFC90;

    uint256 private _burnRate = 0; // Porcentagem de queima de tokens em cada transação
    uint256 private _marketingFee = 0; // Porcentagem de taxas para a carteira de marketing

    constructor() {
        _owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
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
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");

        uint256 burnAmount = amount * _burnRate / 100; // Calcula a quantidade de tokens a serem queimados
        uint256 marketingAmount = amount * _marketingFee / 100; // Calcula a quantidade de tokens a serem enviados para a carteira de marketing
        uint256 transferAmount = amount - burnAmount - marketingAmount; // Calcula a quantidade de tokens a serem transferidos

        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[_marketingWallet] += marketingAmount;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, address(0), burnAmount);
        emit Transfer(sender, _marketingWallet,
        marketingAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}