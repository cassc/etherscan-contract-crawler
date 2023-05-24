/**
 *Submitted for verification at BscScan.com on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TheSmartTrain is IBEP20 {
    string public constant name = "The Smart Train";
    string public constant symbol = "TST";
    uint8 public constant decimals = 18;
    uint256 private constant _totalSupply = 2.5e18; // 2.5 quadrillion tokens

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address private constant _burnAddress = 0x000000000000000000000000000000000000dEaD;
    address private constant _actionGiveawayAddress = 0x8041037F905b67ECAcCb2db14C12b25E7B072Aed;
    address private constant _marketingAddress = 0xc9E2C57a844419DBB00dDc98602dD87fd9EaEB83;
    address private _owner;

    constructor() {
        _owner = msg.sender;
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
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

    function totalSupply() external pure returns (uint256) {
    // Function implementation
}


    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        require(_balances[sender] >= amount, "ERC20: insufficient balance");

        uint256 taxAmount = amount / 50; // 2% tax on buying/selling (2/100 = 1/50)
        uint256 finalAmount = amount - taxAmount;
        uint256 burnAmount = taxAmount / 2; // 1% of the tax is for burning (1/50 * 1/2 = 1/100)
        uint256 actionGiveawayAmount = taxAmount / 2 / 2; // 0.5% of the tax for actions and giveaways (1/50 * 1/2 * 1/2 = 1/200)
        uint256 marketingAmount = taxAmount - actionGiveawayAmount; // Remaining 0.5% of the tax for marketing

        _balances[sender] -= amount;
        _balances[recipient] += finalAmount;
        _balances[_burnAddress] += burnAmount;
        _balances[_actionGiveawayAddress] += actionGiveawayAmount;
        _balances[_marketingAddress] += marketingAmount;

        emit Transfer(sender, recipient, finalAmount);
        emit Transfer(sender, _burnAddress, burnAmount);
        emit Transfer(sender, _actionGiveawayAddress, actionGiveawayAmount);
        emit Transfer(sender, _marketingAddress, marketingAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}