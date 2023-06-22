// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./CreditLine.sol";
import "../../interfaces/ICreditLine.sol";
import "../../external/FixedPoint.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

/**
 * @title The Accountant
 * @notice Library for handling key financial calculations, such as interest and principal accrual.
 * @author Goldfinch
 */

library Accountant {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Signed;
  using FixedPoint for FixedPoint.Unsigned;
  using FixedPoint for int256;
  using FixedPoint for uint256;

  // Scaling factor used by FixedPoint.sol. We need this to convert the fixed point raw values back to unscaled
  uint256 public constant FP_SCALING_FACTOR = 10**18;
  uint256 public constant INTEREST_DECIMALS = 1e18;
  uint256 public constant SECONDS_PER_DAY = 60 * 60 * 24;
  uint256 public constant SECONDS_PER_YEAR = (SECONDS_PER_DAY * 365);

  struct PaymentAllocation {
    uint256 interestPayment;
    uint256 principalPayment;
    uint256 additionalBalancePayment;
  }

  function calculateInterestAndPrincipalAccrued(
    CreditLine cl,
    uint256 timestamp,
    uint256 lateFeeGracePeriod
  ) public view returns (uint256, uint256) {
    uint256 balance = cl.balance(); // gas optimization
    uint256 interestAccrued = calculateInterestAccrued(cl, balance, timestamp, lateFeeGracePeriod);
    uint256 principalAccrued = calculatePrincipalAccrued(cl, balance, timestamp);
    return (interestAccrued, principalAccrued);
  }

  function calculateInterestAndPrincipalAccruedOverPeriod(
    CreditLine cl,
    uint256 balance,
    uint256 startTime,
    uint256 endTime,
    uint256 lateFeeGracePeriod
  ) public view returns (uint256, uint256) {
    uint256 interestAccrued = calculateInterestAccruedOverPeriod(cl, balance, startTime, endTime, lateFeeGracePeriod);
    uint256 principalAccrued = calculatePrincipalAccrued(cl, balance, endTime);
    return (interestAccrued, principalAccrued);
  }

  function calculatePrincipalAccrued(
    ICreditLine cl,
    uint256 balance,
    uint256 timestamp
  ) public view returns (uint256) {
    // If we've already accrued principal as of the term end time, then don't accrue more principal
    uint256 termEndTime = cl.termEndTime();
    if (cl.interestAccruedAsOf() >= termEndTime) {
      return 0;
    }
    if (timestamp >= termEndTime) {
      return balance;
    } else {
      return 0;
    }
  }

  function calculateWritedownFor(
    ICreditLine cl,
    uint256 timestamp,
    uint256 gracePeriodInDays,
    uint256 maxDaysLate
  ) public view returns (uint256, uint256) {
    return calculateWritedownForPrincipal(cl, cl.balance(), timestamp, gracePeriodInDays, maxDaysLate);
  }

  function calculateWritedownForPrincipal(
    ICreditLine cl,
    uint256 principal,
    uint256 timestamp,
    uint256 gracePeriodInDays,
    uint256 maxDaysLate
  ) public view returns (uint256, uint256) {
    FixedPoint.Unsigned memory amountOwedPerDay = calculateAmountOwedForOneDay(cl);
    if (amountOwedPerDay.isEqual(0)) {
      return (0, 0);
    }
    FixedPoint.Unsigned memory fpGracePeriod = FixedPoint.fromUnscaledUint(gracePeriodInDays);
    FixedPoint.Unsigned memory daysLate;

    // Excel math: =min(1,max(0,periods_late_in_days-graceperiod_in_days)/MAX_ALLOWED_DAYS_LATE) grace_period = 30,
    // Before the term end date, we use the interestOwed to calculate the periods late. However, after the loan term
    // has ended, since the interest is a much smaller fraction of the principal, we cannot reliably use interest to
    // calculate the periods later.
    uint256 totalOwed = cl.interestOwed().add(cl.principalOwed());
    daysLate = FixedPoint.fromUnscaledUint(totalOwed).div(amountOwedPerDay);
    if (timestamp > cl.termEndTime()) {
      uint256 secondsLate = timestamp.sub(cl.termEndTime());
      daysLate = daysLate.add(FixedPoint.fromUnscaledUint(secondsLate).div(SECONDS_PER_DAY));
    }

    FixedPoint.Unsigned memory maxLate = FixedPoint.fromUnscaledUint(maxDaysLate);
    FixedPoint.Unsigned memory writedownPercent;
    if (daysLate.isLessThanOrEqual(fpGracePeriod)) {
      // Within the grace period, we don't have to write down, so assume 0%
      writedownPercent = FixedPoint.fromUnscaledUint(0);
    } else {
      writedownPercent = FixedPoint.min(FixedPoint.fromUnscaledUint(1), (daysLate.sub(fpGracePeriod)).div(maxLate));
    }

    FixedPoint.Unsigned memory writedownAmount = writedownPercent.mul(principal).div(FP_SCALING_FACTOR);
    // This will return a number between 0-100 representing the write down percent with no decimals
    uint256 unscaledWritedownPercent = writedownPercent.mul(100).div(FP_SCALING_FACTOR).rawValue;
    return (unscaledWritedownPercent, writedownAmount.rawValue);
  }

  function calculateAmountOwedForOneDay(ICreditLine cl) public view returns (FixedPoint.Unsigned memory interestOwed) {
    // Determine theoretical interestOwed for one full day
    uint256 totalInterestPerYear = cl.balance().mul(cl.interestApr()).div(INTEREST_DECIMALS);
    interestOwed = FixedPoint.fromUnscaledUint(totalInterestPerYear).div(365);
    return interestOwed;
  }

  function calculateInterestAccrued(
    CreditLine cl,
    uint256 balance,
    uint256 timestamp,
    uint256 lateFeeGracePeriodInDays
  ) public view returns (uint256) {
    // We use Math.min here to prevent integer overflow (ie. go negative) when calculating
    // numSecondsElapsed. Typically this shouldn't be possible, because
    // the interestAccruedAsOf couldn't be *after* the current timestamp. However, when assessing
    // we allow this function to be called with a past timestamp, which raises the possibility
    // of overflow.
    // This use of min should not generate incorrect interest calculations, since
    // this function's purpose is just to normalize balances, and handing in a past timestamp
    // will necessarily return zero interest accrued (because zero elapsed time), which is correct.
    uint256 startTime = Math.min(timestamp, cl.interestAccruedAsOf());
    return calculateInterestAccruedOverPeriod(cl, balance, startTime, timestamp, lateFeeGracePeriodInDays);
  }

  function calculateInterestAccruedOverPeriod(
    CreditLine cl,
    uint256 balance,
    uint256 startTime,
    uint256 endTime,
    uint256 lateFeeGracePeriodInDays
  ) public view returns (uint256 interestOwed) {
    uint256 secondsElapsed = endTime.sub(startTime);
    uint256 totalInterestPerYear = balance.mul(cl.interestApr()).div(INTEREST_DECIMALS);
    interestOwed = totalInterestPerYear.mul(secondsElapsed).div(SECONDS_PER_YEAR);

    if (lateFeeApplicable(cl, endTime, lateFeeGracePeriodInDays)) {
      uint256 lateFeeInterestPerYear = balance.mul(cl.lateFeeApr()).div(INTEREST_DECIMALS);
      uint256 additionalLateFeeInterest = lateFeeInterestPerYear.mul(secondsElapsed).div(SECONDS_PER_YEAR);
      interestOwed = interestOwed.add(additionalLateFeeInterest);
    }

    return interestOwed;
  }

  function lateFeeApplicable(
    CreditLine cl,
    uint256 timestamp,
    uint256 gracePeriodInDays
  ) public view returns (bool) {
    uint256 secondsLate = timestamp.sub(cl.lastFullPaymentTime());
    return cl.lateFeeApr() > 0 && secondsLate > gracePeriodInDays.mul(SECONDS_PER_DAY);
  }

  function allocatePayment(
    uint256 paymentAmount,
    uint256 balance,
    uint256 interestOwed,
    uint256 principalOwed
  ) public pure returns (PaymentAllocation memory) {
    uint256 paymentRemaining = paymentAmount;
    uint256 interestPayment = Math.min(interestOwed, paymentRemaining);
    paymentRemaining = paymentRemaining.sub(interestPayment);

    uint256 principalPayment = Math.min(principalOwed, paymentRemaining);
    paymentRemaining = paymentRemaining.sub(principalPayment);

    uint256 balanceRemaining = balance.sub(principalPayment);
    uint256 additionalBalancePayment = Math.min(paymentRemaining, balanceRemaining);

    return
      PaymentAllocation({
        interestPayment: interestPayment,
        principalPayment: principalPayment,
        additionalBalancePayment: additionalBalancePayment
      });
  }
}