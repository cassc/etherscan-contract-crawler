// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './AlphaBetaEqualDepositSplitter.sol';

/**
  ChildOne is the first node that is being used to withdraw from
  Only when ChildOne balance = 0 it will start withdrawing from ChildTwo

  If the deposit amount is at least `MIN_AMOUNT_FOR_EQUAL_SPLIT` of USDC
  It will try to balance out the childs by havng the option to deposit in both

  If the deposit amount is less then `MIN_AMOUNT_FOR_EQUAL_SPLIT` of USDC
  It will deposit in the child that returns the lowest balance

  Either childOne or childTwo can have a limit for the amount of USDC to receive

  Note: the child without a limit can receive two `deposit()` calls
  if the initial amount is at least `MIN_AMOUNT_FOR_EQUAL_SPLIT` USDC
*/
contract AlphaBetaEqualDepositMaxSplitter is AlphaBetaEqualDepositSplitter {
  uint256 private constant NO_LIMIT = type(uint256).max;
  // Max amount of USDC childOne can hold (type(uint256).max = no limit)
  uint256 public immutable MAX_AMOUNT_FOR_CHILD_ONE;
  // Max amount of USDC childTwo can hold (type(uint256).max = no limit)
  uint256 public immutable MAX_AMOUNT_FOR_CHILD_TWO;

  /// @param _initialParent Contract that will be the parent in the tree structure
  /// @param _initialChildOne Contract that will be the initial childOne in the tree structure
  /// @param _initialChildTwo Contract that will be the initial childTwo in the tree structure
  /// @param _MIN_AMOUNT_FOR_EQUAL_SPLIT Min USDC deposit amount to activate logic to equal out balances
  /// @param _MAX_AMOUNT_FOR_CHILD_ONE Max amount of USDC childOne can hold (type(uint256).max = no limit)
  /// @param _MAX_AMOUNT_FOR_CHILD_TWO Max amount of USDC childTwo can hold (type(uint256).max = no limit)
  /// @notice Either `_MAX_AMOUNT_FOR_CHILD_ONE` or `_MAX_AMOUNT_FOR_CHILD_TWO` has to be type(uint256).max
  constructor(
    IMaster _initialParent,
    INode _initialChildOne,
    INode _initialChildTwo,
    uint256 _MIN_AMOUNT_FOR_EQUAL_SPLIT,
    uint256 _MAX_AMOUNT_FOR_CHILD_ONE,
    uint256 _MAX_AMOUNT_FOR_CHILD_TWO
  )
    AlphaBetaEqualDepositSplitter(
      _initialParent,
      _initialChildOne,
      _initialChildTwo,
      _MIN_AMOUNT_FOR_EQUAL_SPLIT
    )
  {
    // Either `_MAX_AMOUNT_FOR_CHILD_ONE` or `_MAX_AMOUNT_FOR_CHILD_TWO` has to be type(uint256).max
    if (_MAX_AMOUNT_FOR_CHILD_ONE != NO_LIMIT && _MAX_AMOUNT_FOR_CHILD_TWO != NO_LIMIT) {
      revert InvalidArg();
    }

    // Either `_MAX_AMOUNT_FOR_CHILD_ONE` or `_MAX_AMOUNT_FOR_CHILD_TWO` has to be non type(uint256).max
    if (_MAX_AMOUNT_FOR_CHILD_ONE == NO_LIMIT && _MAX_AMOUNT_FOR_CHILD_TWO == NO_LIMIT) {
      revert InvalidArg();
    }

    // Write variables to storage
    MAX_AMOUNT_FOR_CHILD_ONE = _MAX_AMOUNT_FOR_CHILD_ONE;
    MAX_AMOUNT_FOR_CHILD_TWO = _MAX_AMOUNT_FOR_CHILD_TWO;
  }

  /// @notice Transfer USDC to one or both childs based on `MAX_AMOUNT_FOR_CHILD_ONE`
  /// @param _amount Amount of USDC to deposit
  function _childOneDeposit(uint256 _amount) internal virtual override {
    // Cache balance in memory
    uint256 childOneBalance = cachedChildOneBalance;

    // Do we want to deposit into childOne at all? If yes, continue
    if (childOneBalance < MAX_AMOUNT_FOR_CHILD_ONE) {
      // Will depositing the full amount result in exceeding the MAX? If yes, continue
      if (childOneBalance + _amount > MAX_AMOUNT_FOR_CHILD_ONE) {
        // How much room if left to hit the USDC cap in childOne
        uint256 childOneAmount = MAX_AMOUNT_FOR_CHILD_ONE - childOneBalance;

        // Deposit amount that will make us hit the cap for childOne
        AlphaBetaSplitter._childOneDeposit(childOneAmount);

        // Deposit leftover USDC into childTwo
        AlphaBetaSplitter._childTwoDeposit(_amount - childOneAmount);
      } else {
        // Deposit all in childOne if depositing full amount will not make us exceed the cap
        AlphaBetaSplitter._childOneDeposit(_amount);
      }
    } else {
      // Deposit all in childTwo (childOne deposit isn't used at all)
      AlphaBetaSplitter._childTwoDeposit(_amount);
    }
  }

  /// @notice Transfer USDC to one or both childs based on `MAX_AMOUNT_FOR_CHILD_TWO`
  /// @param _amount Amount of USDC to deposit
  function _childTwoDeposit(uint256 _amount) internal virtual override {
    // Cache balance in memory
    uint256 childTwoBalance = cachedChildTwoBalance;

    // Do we want to deposit into childTwo at all? If yes, continue
    if (childTwoBalance < MAX_AMOUNT_FOR_CHILD_TWO) {
      // Will depositing the full amount result in exceeding the MAX? If yes, continue
      if (childTwoBalance + _amount > MAX_AMOUNT_FOR_CHILD_TWO) {
        // How much room if left to hit the USDC cap in childTwo
        uint256 childTwoAmount = MAX_AMOUNT_FOR_CHILD_TWO - childTwoBalance;

        // Deposit amount that will make us hit the cap for childTwo
        AlphaBetaSplitter._childTwoDeposit(childTwoAmount);

        // Deposit leftover USDC into childOne
        AlphaBetaSplitter._childOneDeposit(_amount - childTwoAmount);
      } else {
        // Deposit all in childTwo if depositing full amount will not make us exceed the cap
        AlphaBetaSplitter._childTwoDeposit(_amount);
      }
    } else {
      // Deposit all in childOne (childTwo deposit isn't used at all)
      AlphaBetaSplitter._childOneDeposit(_amount);
    }
  }
}