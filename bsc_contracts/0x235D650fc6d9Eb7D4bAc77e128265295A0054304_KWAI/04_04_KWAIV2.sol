// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IFactory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
  function WETH() external pure returns (address);
  function factory() external view returns (address);
}

contract KWAI is IERC20, Ownable {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string constant public name = "Kwai";
    string constant public symbol = "KWAI";
    uint constant public decimals = 18;
    uint256 private _totalSupply = 50 * 1E6 * 10**decimals;

    address public taxWallet;
    uint public fundingTax = 2;
    uint public stakingTax = 1;

    mapping (address => bool) public isExcludedFromTax;

    IRouter public Router;
    address public TOKEN_PAIR;
    
    event TransferFee(address sender, address recipient, uint256 amount);
    event Burn(address sender, uint256 amount);

    constructor(address _taxWallet, address _router) {
        _balances[msg.sender] = _totalSupply;

        taxWallet = _taxWallet;

        isExcludedFromTax[msg.sender] = true;
        isExcludedFromTax[_taxWallet] = true;

        Router = IRouter(_router);
        TOKEN_PAIR = IFactory(Router.factory()).createPair(address(this), 0x55d398326f99059fF775485246999027B3197955);
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external override returns (bool)  {
        _transfer(_msgSender(), to, amount);
        return true;
    }
    
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, this.allowance(owner, spender) + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = this.allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }



    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;

        uint256 receiveAmount = amount;
        if (isExcludedFromTax[sender] || isExcludedFromTax[recipient]) {
            _balances[recipient] += receiveAmount;
        } else {
            if(sender == TOKEN_PAIR || recipient == TOKEN_PAIR) {
                uint256 feeAmount = amount * fundingTax / 100;
                uint256 stakingAmount = amount * stakingTax / 100;

                uint256 totalFee = feeAmount + stakingAmount;
                receiveAmount = amount - totalFee;
                _balances[taxWallet] += totalFee;

                _balances[recipient] += receiveAmount;

                emit TransferFee(sender, taxWallet, totalFee);
            } else {
                _balances[recipient] += receiveAmount;
            }
        }

        emit Transfer(sender, recipient, receiveAmount);

    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }


    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = this.allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function setTaxWallet(address _taxWallet) external onlyOwner {
        require(_taxWallet != address(0), "Token : invalid address.");
        taxWallet = _taxWallet;
    }

    function excludeFromTax(address address_, bool isExcluded_) external onlyOwner {
        isExcludedFromTax[address_] = isExcluded_;
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) external {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}