// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

// https://street-machine.com
// https://t.me/streetmachine_erc
// https://twitter.com/erc_arcade

import "./interfaces/IERC20Burnable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./FeeTracker.sol";

contract FeeToken is IERC20, Ownable, ReentrancyGuard {
    error InsufficientSMCBalance(uint256 _toStake, uint256 _balance);
    error InsufficientSMCAllowance(uint256 _toStake, uint256 _allowance);
    error InsufficientsSMCBalance(uint256 _toUnstake, uint256 _balance);
    error InsufficientsSMCAllowance(uint256 _toUnstake, uint256 _allowance);

    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 18;

    uint256 _totalSupply;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) private feeBlacklist;
    FeeTracker internal feeTracker;

    IERC20Burnable public underlyingToken;

    constructor (address _USDT, address _SMC, string memory __name, string memory __symbol, uint256 __totalSupply) {
        feeTracker = new FeeTracker(_USDT);
        feeTracker.transferOwnership(_msgSender());
        underlyingToken = IERC20Burnable(_SMC);

        _name = __name;
        _symbol = __symbol;

        feeBlacklist[address(this)] = true;
        feeBlacklist[address(0)] = true;

        _mint(_msgSender(), __totalSupply);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        return _transferFrom(_msgSender(), to, amount);
    }

    function allowance(address holder, address spender) public view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        return _transferFrom(from, to, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }
        return true;
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
    unchecked {
        _balances[account] += amount;
    }
        if (!feeBlacklist[account]) {
            try feeTracker.setShare(account, _balances[account]) {} catch {}
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
    }
        if (!feeBlacklist[account]) {
            try feeTracker.setShare(account, _balances[account]) {} catch {}
        }
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
        require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
        _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(_balances[sender] >= amount, "ERC20: insufficient balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;

        if (!feeBlacklist[sender]) {
            try feeTracker.setShare(sender, _balances[sender]) {} catch {}
        }
        if (!feeBlacklist[recipient]) {
            try feeTracker.setShare(recipient, _balances[recipient]) {} catch {}
        }

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setFeeBlacklist(address _account, bool _blacklisted) external nonReentrant onlyOwner {
        feeBlacklist[_account] = _blacklisted;
        feeTracker.setShare(_account, _blacklisted ? 0 : _balances[_account]);
    }

    function getFeeBlacklist(address _account) external view returns (bool) {
        return feeBlacklist[_account];
    }

    function getFeeTracker() external view returns (address) {
        return address(feeTracker);
    }

    receive() external payable {}
}