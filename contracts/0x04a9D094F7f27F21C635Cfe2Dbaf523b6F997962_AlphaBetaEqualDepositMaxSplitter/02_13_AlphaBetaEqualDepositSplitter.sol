// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './AlphaBetaSplitter.sol';

/**
  ChildOne is the first node that is being used to withdraw from
  Only when ChildOne balance = 0 it will start withdrawing from ChildTwo

  If the deposit amount is at least `MIN_AMOUNT_FOR_EQUAL_SPLIT` of USDC
  It will try to balance out the childs by havng the option to deposit in both

  If the deposit amount is less then `MIN_AMOUNT_FOR_EQUAL_SPLIT` of USDC
  It will deposit in the child that returns the lowest balance
*/
contract AlphaBetaEqualDepositSplitter is AlphaBetaSplitter {
  // Min USDC deposit amount to activate logic to equal out balances
  uint256 public immutable MIN_AMOUNT_FOR_EQUAL_SPLIT;

  /// @param _initialParent Contract that will be the parent in the tree structure
  /// @param _initialChildOne Contract that will be the initial childOne in the tree structure
  /// @param _initialChildTwo Contract that will be the initial childTwo in the tree structure
  /// @param _MIN_AMOUNT_FOR_EQUAL_SPLIT Min USDC deposit amount to activate logic to equal out balances
  constructor(
    IMaster _initialParent,
    INode _initialChildOne,
    INode _initialChildTwo,
    uint256 _MIN_AMOUNT_FOR_EQUAL_SPLIT
  ) AlphaBetaSplitter(_initialParent, _initialChildOne, _initialChildTwo) {
    // Write variable to storage
    MIN_AMOUNT_FOR_EQUAL_SPLIT = _MIN_AMOUNT_FOR_EQUAL_SPLIT;
  }

  /// @notice Deposit USDC into one or both childs
  function _deposit() internal virtual override {
    // Amount of USDC in the contract
    uint256 amount = want.balanceOf(address(this));

    // Try to balance out childs if at least `MIN_AMOUNT_FOR_EQUAL_SPLIT` USDC is deposited
    if (amount >= MIN_AMOUNT_FOR_EQUAL_SPLIT) {
      // Cache balances in memory
      uint256 childOneBalance = cachedChildOneBalance;
      uint256 childTwoBalance = cachedChildTwoBalance;

      if (childOneBalance <= childTwoBalance) {
        // How much extra balance does childTWo have?
        // Can be 0
        uint256 childTwoBalanceExtra = childTwoBalance - childOneBalance;

        // If the difference exceeds the amount we can deposit it all in childOne
        // As this brings the two balances close to each other
        if (childTwoBalanceExtra >= amount) {
          // Deposit all USDC into childOne
          _childOneDeposit(amount);
        } else {
          // Depositing in a single child will not make the balances equal
          // So we have to deposit in both childs

          // We know childTwo has a bigger balance
          // Calculting how much to deposit in childTwo
          /**
            Example

            One = 180k USDC
            Two = 220k USDC
            amount = 100k USDC

            childTwoAdd = (100 - (220 - 180)) / 2 = 30k
            childOneAdd = 100k - 30k = 70k
            ---+
            One = 250k USDC
            Two = 250k USDC
          */
          uint256 childTwoAdd = (amount - childTwoBalanceExtra) / 2;
          // Deposit USDC into childTwo
          _childTwoDeposit(childTwoAdd);
          // Deposit leftover USDC into childOne
          _childOneDeposit(amount - childTwoAdd);
        }
      } else {
        // Do same logic as above but for the scenario childOne has a bigger balance

        uint256 childOneBalanceExtra = childOneBalance - childTwoBalance;

        if (childOneBalanceExtra >= amount) {
          // Deposit all USDC into childTwo
          _childTwoDeposit(amount);
        } else {
          uint256 childOneAdd = (amount - childOneBalanceExtra) / 2;
          // Deposit USDC into childOne
          _childOneDeposit(childOneAdd);
          // Deposit leftover USDC into childTwo
          _childTwoDeposit(amount - childOneAdd);
        }
      }
    } else {
      // Use deposit function based on balance
      AlphaBetaSplitter._deposit();
    }
  }
}