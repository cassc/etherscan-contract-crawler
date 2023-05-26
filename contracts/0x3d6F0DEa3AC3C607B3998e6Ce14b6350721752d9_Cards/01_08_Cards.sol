// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Constants.sol";

contract Cards is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 _totalSupply = 10**7 * 10**18;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    uint256 private _tradingTime;
    uint256 private _restrictionLiftTime;
    uint256 private _maxRestrictionAmount = 50000 * 10**18;
    mapping (address => bool) private _isWhitelisted;
    mapping (address => uint256) private _lastTx;

    constructor () public {
        _tradingTime = now + 96 hours;
        _balances[Constants.getTokenOwner()] = _totalSupply; 
        emit Transfer(address(0), Constants.getTokenOwner(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return Constants.getName();
    }

    function symbol() public view returns (string memory) {
        return Constants.getSymbol();
    }

    function decimals() public view returns (uint8) {
        return Constants.getDecimals();
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "CARDS: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "CARDS: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private launchRestrict(sender, recipient, amount) {
        require(sender != address(0), "CARDS: transfer from the zero address");
        require(recipient != address(0), "CARDS: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "CARDS: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "CARDS: approve from the zero address");
        require(spender != address(0), "CARDS: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setTradingStart(uint256 time) external onlyOwner() {
        _tradingTime = time;
        _restrictionLiftTime = time.add(10*60);
    }

    function setRestrictionAmount(uint256 amount) external onlyOwner() {
        _maxRestrictionAmount = amount;
    }

    function whitelistAccount(address account) external onlyOwner() {
        _isWhitelisted[account] = true;
    }

    modifier launchRestrict(address sender, address recipient, uint256 amount) {
        if (_tradingTime > now) {
            require(sender == Constants.getTokenOwner() || recipient == Constants.getTokenOwner(), "CARDS: transfers are disabled");
        } else if (_tradingTime <= now && _restrictionLiftTime > now) {
            require(amount <= _maxRestrictionAmount, "CARDS: amount greater than max limit");
            if (!_isWhitelisted[sender] && !_isWhitelisted[recipient]) {
                require(_lastTx[sender].add(60) <= now && _lastTx[recipient].add(60) <= now, "CARDS: only one tx/min in restricted mode");
                _lastTx[sender] = now;
                _lastTx[recipient] = now;
            } else if (!_isWhitelisted[recipient]){
                require(_lastTx[recipient].add(60) <= now, "CARDS: only one tx/min in restricted mode");
                _lastTx[recipient] = now;
            } else if (!_isWhitelisted[sender]) {
                require(_lastTx[sender].add(60) <= now, "CARDS: only one tx/min in restricted mode");
                _lastTx[sender] = now;
            }
        }
        _;
    }
}