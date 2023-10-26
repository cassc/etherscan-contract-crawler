// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../interfaces/IERC20WithMaxTotalSupply.sol";
import "./utils/Context.sol";

import "../libraries/SafeMath.sol";


// Copied and modified from OpenZeppelin code:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
contract ERC20 is Context, IERC20WithMaxTotalSupply {
    using SafeMath for uint256;

    string _name;
    string _symbol;
    uint256 _totalSupply;
    uint256 _maxTotalSupply;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    constructor(string memory name_, string memory symbol_, uint maxTotalSupply_) public {
        _name = name_;
        _symbol = symbol_;
        _maxTotalSupply = maxTotalSupply_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint) {
        return _totalSupply;
    }

    function maxTotalSupply() public view virtual override returns (uint) {
        return _maxTotalSupply;
    }


    function balanceOf(address account) public view virtual override returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public override virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public virtual override returns (bool) {
        address spender = _msgSender();
        if (spender != sender) {
            uint256 newAllowance = _allowances[sender][spender].sub(amount, "ERC20ForUint256::transferFrom: amount - exceeds spender allowance");
            _approve(sender, spender, newAllowance);
        }

        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20ForUint256::transfer: from -  the zero address");
        require(recipient != address(0), "ERC20ForUint256::transfer: to -  the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20ForUint256::_transfer: amount - exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount, "ERC20ForUint256::_transfer - Add Overflow");

        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20ForUint256::_mint: account - the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _balances[account] = _balances[account].add(amount, "ERC20ForUint256::_mint: amount - exceeds balance");
        _totalSupply = _totalSupply.add(amount, "ERC20ForUint256::_mint: totalSupply - exceeds amount");
        require(_totalSupply <= _maxTotalSupply, "ERC20ForUint256::_mint: maxTotalSupply limit");

        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20ForUint256::_burn: account - the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20ForUint256::_burn: amount - exceeds balance");
        _totalSupply = _totalSupply.sub(amount, "ERC20ForUint256::_burn: totalSupply - exceeds amount");

        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20ForUint256::_approve: owner - the zero address");
        require(spender != address(0), "ERC20ForUint256::_approve: spender - the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}