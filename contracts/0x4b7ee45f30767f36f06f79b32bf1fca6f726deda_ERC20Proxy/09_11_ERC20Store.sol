// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2020 Gemini Trust Company LLC. All Rights Reserved
pragma solidity ^0.7.0;

import "./ERC20ImplUpgradeable.sol";

/** @title  ERC20 compliant token balance store.
  *
  * @notice  This contract serves as the store of balances, allowances, and
  * supply for the ERC20 compliant token. No business logic exists here.
  *
  * @dev  This contract contains no business logic and instead
  * is the final destination for any change in balances, allowances, or token
  * supply. This contract is upgradeable in the sense that its custodian can
  * update the `erc20Impl` address, thus redirecting the source of logic that
  * determines how the balances will be updated.
  *
  * @author  Gemini Trust Company, LLC
  */
contract ERC20Store is ERC20ImplUpgradeable {

    // MEMBERS
    /// @dev  The total token supply.
    uint256 public totalSupply;

    /// @dev  The mapping of balances.
    mapping (address => uint256) public balances;

    /// @dev  The mapping of allowances.
    mapping (address => mapping (address => uint256)) public allowed;

    mapping (address => uint256) public nonces;

    // CONSTRUCTOR
    constructor(address _custodian) ERC20ImplUpgradeable(_custodian) {
        totalSupply = 0;
    }


    // PUBLIC FUNCTIONS
    // (ERC20 Ledger)

    /** @notice  Sets how much `_owner` allows `_spender` to transfer on behalf
      * of `_owner`.
      *
      * @dev  Intended for use by token implementation functions
      * that update spending allowances. The only authorized caller
      * is the active implementation.
      *
      * @param  _owner  The account that will allow an on-behalf-of spend.
      * @param  _spender  The account that will spend on behalf of the owner.
      * @param  _value  The limit of what can be spent.
      */
    function setAllowance(
        address _owner,
        address _spender,
        uint256 _value
    )
        external
        onlyImpl
    {
        allowed[_owner][_spender] = _value;
    }

    /** @notice  Sets the balance of `_owner` to `_newBalance`.
      *
      * @dev  Intended for use by token implementation functions
      * that update balances. The only authorized caller
      * is the active implementation.
      *
      * @param  _owner  The account that will hold a new balance.
      * @param  _newBalance  The balance to set.
      */
    function setBalance(
        address _owner,
        uint256 _newBalance
    )
        external
        onlyImpl
    {
        balances[_owner] = _newBalance;
    }

    /** @notice Adds `_balanceIncrease` to `_owner`'s balance.
      *
      * @dev  Intended for use by token implementation functions
      * that update balances. The only authorized caller
      * is the active implementation.
      * WARNING: the caller is responsible for preventing overflow.
      *
      * @param  _owner  The account that will hold a new balance.
      * @param  _balanceIncrease  The balance to add.
      */
    function addBalance(
        address _owner,
        uint256 _balanceIncrease
    )
        external
        onlyImpl
    {
        balances[_owner] = balances[_owner] + _balanceIncrease;
    }

    function setTotalSupplyAndAddBalance(
        uint256 _newTotalSupply,
        address _owner,
        uint256 _balanceIncrease
    )
        external
        onlyImpl
    {
        totalSupply = _newTotalSupply;
        balances[_owner] = balances[_owner] + _balanceIncrease;
    }

    function setBalanceAndDecreaseTotalSupply(
        address _owner,
        uint256 _newBalance,
        uint256 _supplyDecrease
    )
        external
        onlyImpl
    {
        balances[_owner] = _newBalance;
        totalSupply = totalSupply - _supplyDecrease;
    }

    function setBalanceAndAddBalance(
        address _ownerToSet,
        uint256 _newBalance,
        address _ownerToAdd,
        uint256 _balanceIncrease
    )
        external
        onlyImpl
    {
        balances[_ownerToSet] = _newBalance;
        balances[_ownerToAdd] = balances[_ownerToAdd] + _balanceIncrease;
    }

    function setBalanceAndAllowanceAndAddBalance(
        address _ownerToSet,
        uint256 _newBalance,
        address _spenderToSet,
        uint256 _newAllowance,
        address _ownerToAdd,
        uint256 _balanceIncrease
    )
        external
        onlyImpl
    {
        balances[_ownerToSet] = _newBalance;
        allowed[_ownerToSet][_spenderToSet] = _newAllowance;
        balances[_ownerToAdd] = balances[_ownerToAdd] + _balanceIncrease;
    }

    function balanceAndAllowed(
        address _owner,
        address _spender
    )
        external
        view
        returns (uint256 ownerBalance, uint256 spenderAllowance)
    {
        ownerBalance = balances[_owner];
        spenderAllowance = allowed[_owner][_spender];
    }

    function getNonceAndIncrement(
        address _owner
    )
        external
        onlyImpl
        returns (uint256 current)
    {
        current = nonces[_owner];
        nonces[_owner] = current + 1;
    }
}