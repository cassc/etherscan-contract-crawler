// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

import { Pausable } from './Pausable.sol';
import { GovernedContract } from './GovernedContract.sol';
import { StorageBase } from './StorageBase.sol';
import { Context } from './Context.sol';

import { IGovernedERC20 } from './interfaces/IGovernedERC20.sol';
import { IGovernedContract } from './interfaces/IGovernedContract.sol';
import { IGovernedERC20Storage } from './interfaces/IGovernedERC20Storage.sol';
import { SafeMath } from './libraries/SafeMath.sol';

/**
 * Permanent storage of GovernedERC20 data.
 */

contract GovernedERC20Storage is StorageBase, IGovernedERC20Storage {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function setBalance(address _owner, uint256 _amount) external requireOwner {
        _balances[_owner] = _amount;
    }

    function setAllowance(
        address _owner,
        address _spender,
        uint256 _amount
    ) external requireOwner {
        _allowances[_owner][_spender] = _amount;
    }

    function setTotalSupply(uint256 _amount) external requireOwner {
        _totalSupply = _amount;
    }

    function getBalance(address _account) external view returns (uint256 balance) {
        balance = _balances[_account];
    }

    function getAllowance(address _owner, address _spender)
        external
        view
        returns (uint256 allowance)
    {
        allowance = _allowances[_owner][_spender];
    }

    function getTotalSupply() external view returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }
}

contract GovernedERC20 is Pausable, GovernedContract, IGovernedERC20 {
    using SafeMath for uint256;

    // Data for migration
    //---------------------------------
    GovernedERC20Storage public erc20Storage;

    //---------------------------------

    constructor(address _proxy, address _owner) public Pausable(_owner) GovernedContract(_proxy) {
        erc20Storage = new GovernedERC20Storage();
    }

    // IGovernedContract
    //---------------------------------
    // This function would be called by GovernedProxy on an old implementation to replace it with a new one
    function _destroyERC20(IGovernedContract _newImpl) internal {
        erc20Storage.setOwner(_newImpl);
    }

    //---------------------------------
    // This function would be called on the new implementation if necessary for the upgrade
    function _migrateERC20(address _oldImpl) internal {
        erc20Storage = GovernedERC20Storage(IGovernedERC20(_oldImpl).erc20Storage());
    }

    // ERC20
    //---------------------------------
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view returns (uint256) {
        return erc20Storage.getTotalSupply();
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view returns (uint256) {
        return erc20Storage.getBalance(account);
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return erc20Storage.getAllowance(owner, spender);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address sender,
        address recipient,
        uint256 amount
    ) external requireProxy returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address owner,
        address spender,
        uint256 amount
    ) external requireProxy returns (bool) {
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address spender,
        address sender,
        address recipient,
        uint256 amount
    ) external requireProxy returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 approveAmount = erc20Storage.getAllowance(sender, spender).sub(
            amount,
            'ERC20Token ERC20: transfer amount exceeds allowance'
        );
        _approve(sender, spender, approveAmount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(
        address owner,
        address spender,
        uint256 addedValue
    ) external requireProxy returns (bool) {
        uint256 approveAmount = erc20Storage.getAllowance(owner, spender).add(addedValue);
        _approve(owner, spender, approveAmount);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(
        address owner,
        address spender,
        uint256 subtractedValue
    ) external requireProxy returns (bool) {
        uint256 approveAmount = erc20Storage.getAllowance(owner, spender).sub(
            subtractedValue,
            'ERC20Token ERC20: decreased allowance below zero'
        );
        _approve(owner, spender, approveAmount);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal whenNotPaused {
        require(sender != address(0), 'ERC20Token ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20Token ERC20: transfer to the zero address');

        erc20Storage.setBalance(
            sender,
            erc20Storage.getBalance(sender).sub(
                amount,
                'ERC20Token ERC20: transfer amount exceeds balance'
            )
        );
        erc20Storage.setBalance(recipient, erc20Storage.getBalance(recipient).add(amount));
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal whenNotPaused {
        require(account != address(0), 'ERC20Token ERC20: mint to the zero address');

        erc20Storage.setTotalSupply(erc20Storage.getTotalSupply().add(amount));
        erc20Storage.setBalance(account, erc20Storage.getBalance(account).add(amount));
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal whenNotPaused {
        require(account != address(0), 'ERC20Token ERC20: burn from the zero address');

        erc20Storage.setBalance(
            account,
            erc20Storage.getBalance(account).sub(
                amount,
                'ERC20Token ERC20: burn amount exceeds balance'
            )
        );
        erc20Storage.setTotalSupply(erc20Storage.getTotalSupply().sub(amount));
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal whenNotPaused {
        require(owner != address(0), 'ERC20Token ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20Token ERC20: approve to the zero address');

        erc20Storage.setAllowance(owner, spender, amount);
    }
}