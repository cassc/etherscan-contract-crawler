/**
 *Submitted for verification at BscScan.com on 2023-05-02
*/

//SPDX-License-Identifier: MIT
/**
 *Submitted for verification at Etherscan.io on 2023-05-02
*/

// t.me/AIeducation
// AIeducation.com
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

contract Aieducation is IERC20 {
    string public name = "Aieducation";
    string public symbol = "AIEDU";
    uint8 public decimals = 18;
    uint256 private _totalSupply = 100000000 * 10 ** uint256(decimals);
    address private _owner;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _blacklist;

    constructor() {
        _owner = msg.sender;
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
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
        require(!_blacklist[msg.sender], "ERC20: sender is blacklisted");
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= _balances[sender], "ERC20: transfer amount exceeds balance");
        require(amount <= _allowances[sender][msg.sender], "ERC20: transfer amount exceeds allowance");
        require(!_blacklist[sender], "ERC20: sender is blacklisted");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function addToBlacklist(address account) public {
        require(msg.sender == _owner, "ERC20: only owner can add to blacklist");
        _blacklist[account] = true;
    }

    function removeFromBlacklist(address account) public {
        require(msg.sender == _owner, "ERC20: only owner can remove from blacklist");
        _blacklist[account] = false;
    }

    function burn(uint256 amount) public {
        require(amount <= _balances[msg.sender], "ERC20: burn amount exceeds balance");
        require(!_blacklist[msg.sender], "ERC20: sender is blacklisted");
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _allowances[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _allowances[msg.sender][spender] = currentAllowance - subtractedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function renounceOwnership() public {
        require(msg.sender == _owner, "ERC20: only owner can renounce ownership");
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == _owner, "ERC20: only owner can transfer ownership");
        require(newOwner != address(0), "ERC20: new owner is the zero address");
        _owner = newOwner;
    }
}