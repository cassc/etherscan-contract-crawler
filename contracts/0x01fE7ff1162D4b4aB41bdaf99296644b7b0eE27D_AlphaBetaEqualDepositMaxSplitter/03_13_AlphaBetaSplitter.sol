// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '../base/BaseSplitter.sol';

/**
  ChildOne is the first node that is being used to withdraw from
  Only when ChildOne balance = 0 it will start withdrawing from ChildTwo

  It will deposit in the child that returns the lowest balance (childOne first)
*/
contract AlphaBetaSplitter is BaseSplitter {
  using SafeERC20 for IERC20;

  /// @param _initialParent Contract that will be the parent in the tree structure
  /// @param _initialChildOne Contract that will be the initial childOne in the tree structure
  /// @param _initialChildTwo Contract that will be the initial childTwo in the tree structure
  constructor(
    IMaster _initialParent,
    INode _initialChildOne,
    INode _initialChildTwo
  ) BaseSplitter(_initialParent, _initialChildOne, _initialChildTwo) {}

  /// @notice Signal to withdraw `_amount` of USDC from the underlying nodes into core
  /// @param _amount Amount of USDC to withdraw
  function _withdraw(uint256 _amount) internal virtual override {
    // First in line for liquidations
    uint256 childOneBalance = cachedChildOneBalance;

    // If the amount exceeds childOne balance, it will start withdrawing from childTwo
    if (_amount > childOneBalance) {
      // Withdraw all USDC from childOne
      if (childOneBalance != 0) childOne.withdrawAll();

      // Withdraw USDC from childTwo when childOne balance hits zero
      childTwo.withdraw(_amount - childOneBalance);
    } else {
      // Withdraw from childOne
      childOne.withdraw(_amount);
    }
  }

  /// @notice Transfer USDC to childOne and call deposit
  /// @param _amount Amount of USDC to deposit
  function _childOneDeposit(uint256 _amount) internal virtual {
    // Transfer USDC to childOne
    want.safeTransfer(address(childOne), _amount);

    // Signal childOne it received a deposit
    childOne.deposit();
  }

  /// @notice Transfer USDC to childTwo and call deposit
  /// @param _amount Amount of USDC to deposit
  function _childTwoDeposit(uint256 _amount) internal virtual {
    // Transfer USDC to childTwo
    want.safeTransfer(address(childTwo), _amount);

    // Signal childOne it received a deposit
    childTwo.deposit();
  }

  /// @notice Deposit USDC into one child
  function _deposit() internal virtual override {
    // Deposit USDC into strategy that has the lowest balance
    if (cachedChildOneBalance <= cachedChildTwoBalance) {
      _childOneDeposit(want.balanceOf(address(this)));
    } else {
      _childTwoDeposit(want.balanceOf(address(this)));
    }
  }
}