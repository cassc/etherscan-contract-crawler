// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {SaturatingSub} from "../../../library/SaturatingSub.sol";
import {ILoan} from "../../../interfaces/ILoan.sol";

/**
 * @title CallableLoanAccountant
 * @notice Library for handling allocations of payments and interest calculations
 *         for callable loans.
 * @author Goldfinch
 */
library CallableLoanAccountant {
  using SaturatingSub for uint256;

  uint256 internal constant INTEREST_DECIMALS = 1e18;
  uint256 internal constant SECONDS_PER_DAY = 60 * 60 * 24;
  uint256 internal constant SECONDS_PER_YEAR = SECONDS_PER_DAY * 365;

  /// @notice Allocate a payment to proper balances according to the payment waterfall.
  ///         Expected payment waterfall:
  ///         1. Interest owed
  ///         2. Principal owed
  ///         3. Interest accrued
  ///         4. Interest guaranteed to accrue before the next principal settlement
  ///         5. Any additional remaining balance
  /// @param paymentAmount amount to allocate
  /// @param balance Balance = Remaining principal outstanding
  /// @param interestOwed interest owed on the credit line up to the last due time
  /// @param interestAccrued interest accrued between the last due time and the present time
  /// @param interestRate interest which is guaranteed to accrue between now and
  ///                      the next time principal is settled
  /// @param timeUntilNextPrincipalSettlement time at which the next principal payment is due
  /// @param principalOwed principal owed on the credit line
  /// @param guaranteedFutureInterestPaid guaranteed future interest which has already been paid
  /// @return PaymentAllocation payment allocation
  function allocatePayment(
    uint256 paymentAmount,
    uint256 interestOwed,
    uint256 interestAccrued,
    uint256 principalOwed,
    uint256 interestRate,
    uint256 timeUntilNextPrincipalSettlement,
    uint256 balance,
    uint256 guaranteedFutureInterestPaid
  ) internal pure returns (ILoan.PaymentAllocation memory) {
    uint256 paymentRemaining = paymentAmount;
    uint256 owedInterestPayment = Math.min(interestOwed, paymentRemaining);
    paymentRemaining -= owedInterestPayment;

    uint256 principalPayment = Math.min(principalOwed, paymentRemaining);
    paymentRemaining -= principalPayment;

    uint256 accruedInterestPayment = Math.min(interestAccrued, paymentRemaining);
    paymentRemaining -= accruedInterestPayment;

    uint256 balanceRemaining = balance - principalPayment;
    uint256 guaranteedFutureInterest = calculateInterest({
      secondsElapsed: timeUntilNextPrincipalSettlement,
      principal: balanceRemaining,
      interestApr: interestRate
    });
    uint256 guaranteedFutureAccruedInterestPayment = Math.min(
      guaranteedFutureInterest.saturatingSub(guaranteedFutureInterestPaid),
      paymentRemaining
    );
    paymentRemaining -= guaranteedFutureAccruedInterestPayment;

    uint256 additionalBalancePayment = Math.min(paymentRemaining, balanceRemaining);
    paymentRemaining -= additionalBalancePayment;

    return
      ILoan.PaymentAllocation({
        owedInterestPayment: owedInterestPayment,
        accruedInterestPayment: accruedInterestPayment + guaranteedFutureAccruedInterestPayment,
        principalPayment: principalPayment,
        additionalBalancePayment: additionalBalancePayment,
        paymentRemaining: paymentRemaining
      });
  }

  /**
   * Calculates flat interest accrued over a period of time given constant principal.
   */
  function calculateInterest(
    uint256 secondsElapsed,
    uint256 principal,
    uint256 interestApr
  ) internal pure returns (uint256) {
    // More readable, but less gas efficient implementation:
    // uint256 totalInterestPerYear = (principal * interestApr) / INTEREST_DECIMALS;
    // interest = (totalInterestPerYear * secondsElapsed) / SECONDS_PER_YEAR;

    return (principal * interestApr * secondsElapsed) / (INTEREST_DECIMALS * SECONDS_PER_YEAR);
  }

  /**
   * Calculates interest accrued along with late interest over a given time period given constant principal
   *
   */
  function calculateInterest(
    uint256 start,
    uint256 end,
    uint256 lateFeesStartsAt,
    uint256 lateFeesEndAt,
    uint256 principal,
    uint256 interestApr,
    uint256 lateInterestAdditionalApr
  ) internal pure returns (uint256 interest) {
    if (end <= start) return 0;
    uint256 totalDuration = end - start;
    interest = calculateInterest(totalDuration, principal, interestApr);
    if (lateFeesStartsAt < end && lateFeesEndAt > lateFeesStartsAt) {
      uint256 lateDuration = Math.min(lateFeesEndAt, end).saturatingSub(
        Math.max(lateFeesStartsAt, start)
      );
      interest += calculateInterest(lateDuration, principal, lateInterestAdditionalApr);
    }
  }
}