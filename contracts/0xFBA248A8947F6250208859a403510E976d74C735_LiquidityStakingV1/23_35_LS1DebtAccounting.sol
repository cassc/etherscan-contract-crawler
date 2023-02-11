// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { LS1Types } from '../lib/LS1Types.sol';
import { LS1BorrowerAllocations } from './LS1BorrowerAllocations.sol';

/**
 * @title LS1DebtAccounting
 * @author MarginX
 *
 * @dev Allows converting an overdue balance into "debt", which is accounted for separately from
 *  the staked and borrowed balances. This allows the system to rebalance/restabilize itself in the
 *  case where a borrower fails to return borrowed funds on time.
 *
 *  The shortfall debt calculation is as follows:
 *
 *    - Let A be the total active balance.
 *    - Let B be the total borrowed balance.
 *    - Let X be the total inactive balance.
 *    - Then, a shortfall occurs if at any point B > A.
 *    - The shortfall debt amount is `D = B - A`
 *    - The borrowed balances are decreased by `B_new = B - D`
 *    - The inactive balances are decreased by `X_new = X - D`
 *    - The shortfall index is recorded as `Y = X_new / X`
 *    - The borrower and staker debt balances are increased by `D`
 *
 *  Note that `A + X >= B` (The active and inactive balances are at least the borrowed balance.)
 *  This implies that `X >= D` (The inactive balance is always at least the shortfall debt.)
 */
abstract contract LS1DebtAccounting is
  LS1BorrowerAllocations
{
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMathUpgradeable for uint256;
  using MathUpgradeable for uint256;

  // ============ Events ============

  event ConvertedInactiveBalancesToDebt(
    uint256 shortfallAmount,
    uint256 shortfallIndex,
    uint256 newInactiveBalance
  );

  event DebtMarked(
    address indexed borrower,
    uint256 amount,
    uint256 newBorrowedBalance,
    uint256 newDebtBalance
  );

  // ============ External Functions ============

  /**
   * @notice Restrict a borrower from borrowing. The borrower must have exceeded their borrowing
   *  allocation. Can be called by anyone.
   *
   *  Unlike markDebt(), this function can be called even if the contract in TOTAL is not insolvent.
   */
  function restrictBorrower(
    address borrower
  )
    external
    nonReentrant
  {
    require(
      isBorrowerOverdue(borrower),
      'Borrower !overdue'
    );
    _setBorrowingRestriction(borrower, true);
  }

  /**
   * @notice Convert the shortfall amount between the active and borrowed balances into “debt.”
   *
   *  The function determines the size of the debt, and then does the following:
   *   - Assign the debt to borrowers, taking the same amount out of their borrowed balance.
   *   - Impose borrow restrictions on borrowers to whom the debt was assigned.
   *   - Socialize the loss pro-rata across inactive balances. Each balance with a loss receives
   *     an equal amount of debt balance that can be withdrawn as debts are repaid.
   *
   * @param  borrowers  A list of borrowers who are responsible for the full shortfall amount.
   *
   * @return The shortfall debt amount.
   */
  function markDebt(
    address[] calldata borrowers
  )
    external
    nonReentrant
    returns (uint256)
  {
    // The debt is equal to the difference between the total active and total borrowed balances.
    uint256 totalActiveCurrent = getTotalActiveBalanceCurrentEpoch();
    uint256 totalBorrowed = _TOTAL_BORROWED_BALANCE_;
    require(totalBorrowed > totalActiveCurrent, 'No shortfall');
    uint256 shortfallDebt = totalBorrowed.sub(totalActiveCurrent);

    // Attribute debt to borrowers.
    _attributeDebtToBorrowers(shortfallDebt, totalActiveCurrent, borrowers);

    // Apply the debt to inactive balances, moving the same amount into users debt balances.
    _convertInactiveBalanceToDebt(shortfallDebt);

    return shortfallDebt;
  }

  // ============ Public Functions ============

  /**
   * @notice Whether the borrower is overdue on a payment, and is currently subject to having their
   *  borrowing rights revoked.
   *
   * @param  borrower  The borrower to check.
   */
  function isBorrowerOverdue(
    address borrower
  )
    public
    view
    returns (bool)
  {
    uint256 allocatedBalance = getAllocatedBalanceCurrentEpoch(borrower);
    uint256 borrowedBalance = _BORROWED_BALANCES_[borrower];
    return borrowedBalance > allocatedBalance;
  }

  // ============ Private Functions ============

  /**
   * @dev Helper function to partially or fully convert inactive balances to debt.
   *
   * @param  shortfallDebt  The shortfall amount: borrowed balances less active balances.
   */
  function _convertInactiveBalanceToDebt(
    uint256 shortfallDebt
  )
    private
  {
    // Get the total inactive balance.
    uint256 oldInactiveBalance = getTotalInactiveBalanceCurrentEpoch();

    // Calculate the index factor for the shortfall.
    uint256 newInactiveBalance = 0;
    uint256 shortfallIndex = 0;
    if (oldInactiveBalance > shortfallDebt) {
      newInactiveBalance = oldInactiveBalance.sub(shortfallDebt);
      shortfallIndex = SHORTFALL_INDEX_BASE.mul(newInactiveBalance).div(oldInactiveBalance);
    }

    // Get the shortfall amount applied to inactive balances.
    uint256 shortfallAmount = oldInactiveBalance.sub(newInactiveBalance);

    // Apply the loss. This moves the debt from stakers' inactive balances to their debt balances.
    _applyShortfall(shortfallAmount, shortfallIndex);
    emit ConvertedInactiveBalancesToDebt(shortfallAmount, shortfallIndex, newInactiveBalance);
  }

  /**
   * @dev Helper function to attribute debt to borrowers, adding it to their debt balances.
   *
   * @param  shortfallDebt       The shortfall amount: borrowed balances less active balances.
   * @param  totalActiveCurrent  The total active balance for the current epoch.
   * @param  borrowers           A list of borrowers responsible for the full shortfall amount.
   */
  function _attributeDebtToBorrowers(
    uint256 shortfallDebt,
    uint256 totalActiveCurrent,
    address[] calldata borrowers
  ) private {
    // Find borrowers to attribute the total debt amount to. The sum of all borrower shortfalls is
    // always at least equal to the overall shortfall, so it is always possible to specify a list
    // of borrowers whose excess borrows cover the full shortfall amount.
    //
    // Denominate values in “points” scaled by TOTAL_ALLOCATION to avoid rounding.
    uint256 debtToBeAttributedPoints = shortfallDebt.mul(TOTAL_ALLOCATION);
    uint256 shortfallDebtAfterRounding = 0;
    for (uint256 i = 0; i < borrowers.length; i++) {
      address borrower = borrowers[i];
      uint256 borrowedBalanceTokenAmount = _BORROWED_BALANCES_[borrower];
      uint256 borrowedBalancePoints = borrowedBalanceTokenAmount.mul(TOTAL_ALLOCATION);
      uint256 allocationPoints = getAllocationFractionCurrentEpoch(borrower);
      uint256 allocatedBalancePoints = totalActiveCurrent.mul(allocationPoints);

      // Skip this borrower if they have not exceeded their allocation.
      if (borrowedBalancePoints <= allocatedBalancePoints) {
        continue;
      }

      // Calculate the borrower's debt, and limit to the remaining amount to be allocated.
      uint256 borrowerDebtPoints = borrowedBalancePoints.sub(allocatedBalancePoints);
      borrowerDebtPoints = MathUpgradeable.min(borrowerDebtPoints, debtToBeAttributedPoints);

      // Move the debt from the borrowers' borrowed balance to the debt balance. Rounding may occur
      // when converting from “points” to tokens. We round up to ensure the final borrowed balance
      // is not greater than the allocated balance.
      uint256 borrowerDebtTokenAmount = borrowerDebtPoints.ceilDiv(TOTAL_ALLOCATION);
      uint256 newDebtBalance = _BORROWER_DEBT_BALANCES_[borrower].add(borrowerDebtTokenAmount);
      uint256 newBorrowedBalance = borrowedBalanceTokenAmount.sub(borrowerDebtTokenAmount);
      _BORROWER_DEBT_BALANCES_[borrower] = newDebtBalance;
      _BORROWED_BALANCES_[borrower] = newBorrowedBalance;
      emit DebtMarked(borrower, borrowerDebtTokenAmount, newBorrowedBalance, newDebtBalance);
      shortfallDebtAfterRounding = shortfallDebtAfterRounding.add(borrowerDebtTokenAmount);

      // Restrict the borrower from further borrowing.
      _setBorrowingRestriction(borrower, true);

      // Update the remaining amount to allocate.
      debtToBeAttributedPoints = debtToBeAttributedPoints.sub(borrowerDebtPoints);

      // Exit early if all debt was allocated.
      if (debtToBeAttributedPoints == 0) {
        break;
      }
    }

    // Require the borrowers to cover the full debt amount. This should always be possible.
    require(
      debtToBeAttributedPoints == 0,
      'Do not cover the shortfall'
    );

    // Move the debt from the total borrowed balance to the total debt balance.
    _TOTAL_BORROWED_BALANCE_ = _TOTAL_BORROWED_BALANCE_.sub(shortfallDebtAfterRounding);
    _TOTAL_BORROWER_DEBT_BALANCE_ = _TOTAL_BORROWER_DEBT_BALANCE_.add(shortfallDebtAfterRounding);
  }
}