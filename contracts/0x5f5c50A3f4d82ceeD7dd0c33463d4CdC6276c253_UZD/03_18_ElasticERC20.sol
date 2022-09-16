// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import './PricableAsset.sol';

/**
 * @dev OpenZeppelin v4.7.0 ERC20 fork
 */
contract ElasticERC20 is Context, IERC20Metadata, PricableAsset {
    using Math for uint256;

    uint8 public constant DEFAULT_DECIMALS = 18;
    uint256 public constant DEFAULT_DECIMALS_FACTOR = uint256(10)**DEFAULT_DECIMALS;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(
        string memory name_,
        string memory symbol_,
        address priceOracle_
    ) PricableAsset(priceOracle_) {
        _name = name_;
        _symbol = symbol_;
    }

    function _convertToNominalCached(uint256 value, Math.Rounding rounding)
        internal
        virtual
        returns (uint256 nominal)
    {
        if (value == type(uint256).max) return type(uint256).max;

        return value.mulDiv(DEFAULT_DECIMALS_FACTOR, assetPriceCached(), rounding);
    }

    function _convertFromNominalCached(uint256 nominal, Math.Rounding rounding)
        internal
        virtual
        returns (uint256 value)
    {
        if (nominal == type(uint256).max) return type(uint256).max;

        return nominal.mulDiv(assetPriceCached(), DEFAULT_DECIMALS_FACTOR, rounding);
    }

    function _convertToNominal(uint256 value, Math.Rounding rounding)
        internal
        view
        virtual
        returns (uint256 nominal)
    {
        if (value == type(uint256).max) return type(uint256).max;

        return value.mulDiv(DEFAULT_DECIMALS_FACTOR, assetPrice(), rounding);
    }

    function _convertFromNominal(uint256 nominal, Math.Rounding rounding)
        internal
        view
        virtual
        returns (uint256 value)
    {
        if (nominal == type(uint256).max) return type(uint256).max;

        return nominal.mulDiv(assetPrice(), DEFAULT_DECIMALS_FACTOR, rounding);
    }

    function totalSupplyNominal() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOfNominal(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowanceNominal(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    // IERC20
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        // don't cache price
        return _convertFromNominal(_totalSupply, Math.Rounding.Down);
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        // don't cache price
        return _convertFromNominal(_balances[account], Math.Rounding.Down);
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        // don't cache price
        return _convertFromNominal(_allowances[owner][spender], Math.Rounding.Down);
    }

    function _allowanceCached(address owner, address spender) internal virtual returns (uint256) {
        return _convertFromNominalCached(_allowances[owner][spender], Math.Rounding.Down);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, _convertToNominalCached(amount, Math.Rounding.Up), amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        uint256 nominalAmount = _convertToNominalCached(amount, Math.Rounding.Up);
        _spendAllowance(from, spender, amount);
        _transfer(from, to, nominalAmount, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowanceCached(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = _allowanceCached(owner, spender);
        require(currentAllowance >= subtractedValue, 'ERC20: decreased allowance below zero');
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 nominal,
        uint256 value
    ) internal virtual {
        require(from != address(0), 'ERC20: transfer from the zero address');
        require(to != address(0), 'ERC20: transfer to the zero address');

        uint256 fromBalance = _balances[from];
        require(fromBalance >= nominal, 'ERC20: transfer amount exceeds balance');
        unchecked {
            _balances[from] = fromBalance - nominal;
        }
        _balances[to] += nominal;

        emit Transfer(from, to, value);
    }

    function _mint(
        address account,
        uint256 nominal,
        uint256 value
    ) internal virtual {
        require(account != address(0), 'ERC20: mint to the zero address');

        _totalSupply += nominal;
        _balances[account] += nominal;
        emit Transfer(address(0), account, value);
    }

    function _burn(
        address account,
        uint256 nominal,
        uint256 value
    ) internal virtual {
        require(account != address(0), 'ERC20: burn from the zero address');

        uint256 accountBalance = balanceOfNominal(account);
        require(accountBalance >= nominal, 'ERC20: burn amount exceeds balance');
        unchecked {
            _balances[account] = accountBalance - nominal;
        }
        _totalSupply -= nominal;

        emit Transfer(account, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal virtual {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

        _allowances[owner][spender] = _convertToNominalCached(value, Math.Rounding.Up);
        emit Approval(owner, spender, value);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 value
    ) internal virtual {
        uint256 currentAllowance = _allowanceCached(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= value, 'ERC20: insufficient allowance');
            unchecked {
                _approve(owner, spender, currentAllowance - value);
            }
        }
    }
}