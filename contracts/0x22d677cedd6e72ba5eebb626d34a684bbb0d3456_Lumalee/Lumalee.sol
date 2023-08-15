/**
 *Submitted for verification at Etherscan.io on 2023-07-01
*/

// SPDX-License-Identifier: MIT

/*
 * Website : https://lumaleeerc20.com
 * Telegram : https://t.me/LumaleeERC20Announcements
 * Twitter : https://twitter.com/LumaleeERC20
 * WhitePaper : https://lumaleeerc20.gitbook.io/lumaleeerc20/
*/
pragma solidity ^0.8.19;

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

contract Lumalee is IERC20 {
    using SafeMath for uint256;

    string private _name = "LUMALEE";
    string private _symbol = "LUMA";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 420000000000000 * (10**uint256(_decimals));

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address private _owner;
    mapping(address => bool) private _excludedFees;
    mapping(address => bool) private _excludedRewards;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only contract owner can call this function");
        _;
    }

    constructor() {
        _owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(amount > 0, "Amount must be greater than zero");

        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(amount > 0, "Amount must be greater than zero");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);

        emit Transfer(sender, recipient, amount);
        emit Approval(sender, msg.sender, _allowances[sender][msg.sender]);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedAmount) public returns (bool) {
        _allowances[msg.sender][spender] = _allowances[msg.sender][spender].add(addedAmount);
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedAmount) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedAmount, "Decreased allowance below zero");
        _allowances[msg.sender][spender] = currentAllowance.sub(subtractedAmount);
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        _owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        _owner = address(0);
    }

    function excludeFromFee(address account) public onlyOwner {
        _excludedFees[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _excludedFees[account] = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _excludedFees[account];
    }

    function excludeFromReward(address account) public onlyOwner {
        _excludedRewards[account] = true;
    }

    function includeInReward(address account) public onlyOwner {
        _excludedRewards[account] = false;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _excludedRewards[account];
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function getContractFunctions() public pure returns (string memory) {
        return "name(), symbol(), decimals(), totalSupply(), balanceOf(), transfer(), transferFrom(), approve(), allowance(), increaseAllowance(), decreaseAllowance(), transferOwnership(), renounceOwnership(), excludeFromFee(), includeInFee(), isExcludedFromFee(), excludeFromReward(), includeInReward(), isExcludedFromReward(), getOwner(), getContractFunctions()";
    }
}