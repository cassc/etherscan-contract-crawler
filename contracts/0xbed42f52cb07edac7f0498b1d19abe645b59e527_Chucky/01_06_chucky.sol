// SPDX-License-Identifier: MIT
/**
* Chucky is here to stab all dogs and frogs that try to stop him.
*/ 
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Chucky is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    using Address for address;

    string private _name = "Chucky";
    string private _symbol = "CHUCKY";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 69420000000 * 10**uint256(_decimals);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address payable private _deadAddress = payable(0x000000000000000000000000000000000000dEaD);
    address payable private _marketingAddress = payable(0xe91393fA22b3861d0ac93Be82cC19981F3Aae7C4);

    uint256 private _taxFee = 1;
    uint256 private _marketingFee = 1;

    constructor() {
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        
        uint256 taxAmount = amount.mul(_taxFee).div(100);
        uint256 marketingAmount = amount.mul(_marketingFee).div(100);
        uint256 transferAmount = amount.sub(taxAmount).sub(marketingAmount);
        
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(transferAmount);
        
        // Pay tax to the dead address
        if (taxAmount > 0) {
            _transferWithTax(sender, _deadAddress, taxAmount);
        }
        
        // Pay marketing fee to the marketing address
        if (marketingAmount > 0) {
            _transferWithTax(sender, _marketingAddress, marketingAmount);
        }
        
        emit Transfer(sender, recipient, transferAmount);
    }

    function _transferWithTax(address sender, address payable recipient, uint256 amount) internal {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}