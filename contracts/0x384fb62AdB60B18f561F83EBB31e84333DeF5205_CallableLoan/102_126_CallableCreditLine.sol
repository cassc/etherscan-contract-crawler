// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

// import {console2 as console} from "forge-std/console2.sol";

import {ISchedule} from "../../../../interfaces/ISchedule.sol";
import {IGoldfinchConfig} from "../../../../interfaces/IGoldfinchConfig.sol";
import {ICallableLoan} from "../../../../interfaces/ICallableLoan.sol";
import {ICallableLoanErrors} from "../../../../interfaces/ICallableLoanErrors.sol";
import {ILoan} from "../../../../interfaces/ILoan.sol";

import {SaturatingSub} from "../../../../library/SaturatingSub.sol";
import {CallableLoanAccountant} from "../CallableLoanAccountant.sol";
import {LoanPhase} from "../../../../interfaces/ICallableLoan.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import {Tranche} from "./Tranche.sol";
import {Waterfall} from "./Waterfall.sol";
import {PaymentSchedule, PaymentScheduleLogic} from "../../schedule/PaymentSchedule.sol";
import {CallableLoanConfigHelper} from "../CallableLoanConfigHelper.sol";

using CallableCreditLineLogic for CallableCreditLine global;

/**
 * @notice Handles the accounting of borrower obligations in a callable loan.
 *         Supports
 *         - Deposit of funds before the loan is drawn down.
 *         - Drawdown of funds which should start the loan.
 *         - Repayment of borrowed funds.
 *         - Withdrawal of undrawndown funds which were not used to drawdown the loan.
 *         See "./notes.md" for notes on entities in the CallableCreditLine
 */

// TODO: Add notes to fields to describe each (pseudo-natspec)
/// @param _numLockupPeriods Describes when newly submitted call requests are rolled over
///                          to the next call request period.
///                          Number of periods is relative to the end date of a call request period.
///                          e.g. if _numLockupPeriods is 2, then newly submitted call requests
///                          in the last two periods of a call request period will be rolled over
///                          to the next call request period.
struct CallableCreditLine {
  IGoldfinchConfig _config;
  uint256 _fundableAt;
  uint256 _limit;
  uint256 _interestApr;
  uint256 _lateAdditionalApr;
  uint256 _numLockupPeriods;
  uint256 _checkpointedAsOf;
  uint256 _lastFullPaymentTime;
  uint256 _totalInterestOwedAtLastCheckpoint;
  uint256 _totalInterestAccruedAtLastCheckpoint;
  Waterfall _waterfall;
  PaymentSchedule _paymentSchedule;
  uint[20] __padding;
}

struct SettledTrancheInfo {
  uint256 principalDeposited;
  uint256 principalPaid;
  uint256 principalReserved;
  uint256 interestPaid;
}

library CallableCreditLineLogic {
  using SaturatingSub for uint256;
  using CallableLoanConfigHelper for IGoldfinchConfig;
  using PreviewCallableCreditLineLogic for CallableCreditLine;
  using CheckpointedCallableCreditLineLogic for CallableCreditLine;

  /*================================================================================
  Constants
  ================================================================================*/
  uint256 internal constant SECONDS_PER_DAY = 60 * 60 * 24;

  /*================================================================================
  Errors
  ================================================================================*/
  function initialize(
    CallableCreditLine storage cl,
    IGoldfinchConfig _config,
    uint256 _fundableAt,
    uint256 _numLockupPeriods,
    ISchedule _schedule,
    uint256 _interestApr,
    uint256 _lateAdditionalApr,
    uint256 _limit
  ) internal {
    if (cl._checkpointedAsOf != 0) {
      revert ICallableLoanErrors.CannotReinitialize();
    }
    cl._config = _config;
    cl._limit = _limit;
    cl._numLockupPeriods = _numLockupPeriods;
    cl._fundableAt = _fundableAt;
    // Keep PaymentSchedule's startTime "0" until it is set at first drawdown (schedule start).
    cl._paymentSchedule = PaymentSchedule({schedule: _schedule, startTime: 0});
    cl._waterfall.initialize(_schedule.totalPrincipalPeriods());
    cl._interestApr = _interestApr;
    cl._lateAdditionalApr = _lateAdditionalApr;
    cl._checkpointedAsOf = block.timestamp;

    // Initialize cumulative/settled values
    cl._lastFullPaymentTime = block.timestamp;
    cl._totalInterestAccruedAtLastCheckpoint = 0;
    cl._totalInterestOwedAtLastCheckpoint = 0;
  }

  /*================================================================================
  Main Write Functions
  ================================================================================*/
  function pay(
    CallableCreditLine storage cl,
    uint256 principalPayment,
    uint256 interestPayment
  ) internal {
    if (cl.loanPhase() != LoanPhase.InProgress) {
      revert ICallableLoanErrors.InvalidLoanPhase(cl.loanPhase(), LoanPhase.InProgress);
    }

    cl._waterfall.pay({
      principalAmount: principalPayment,
      interestAmount: interestPayment,
      reserveTranchesIndexStart: cl._paymentSchedule.currentPrincipalPeriod()
    });

    if (cl.principalOwed() == 0 && cl.interestOwed() == 0) {
      cl._lastFullPaymentTime = Math.max(block.timestamp, cl._lastFullPaymentTime);
    }

    for (
      uint256 periodIndex = cl._paymentSchedule.currentPeriod();
      periodIndex < cl._paymentSchedule.schedule.periodsInTerm();
      periodIndex++
    ) {
      uint256 periodEndTime = cl._paymentSchedule.periodEndTime(periodIndex);

      if (
        periodEndTime <= cl.nextPrincipalDueTime() &&
        cl.principalOwedAt(periodEndTime) == 0 &&
        cl.interestOwedAt(periodEndTime) == 0
      ) {
        cl._lastFullPaymentTime = Math.max(block.timestamp, periodEndTime);
      } else {
        // We break out of the loop if we hit a period in which:
        // 1. There is still principal or interest owed
        // 2. The period is after the next principal due time
        break;
      }
    }
  }

  /// @notice Updates accounting for the given drawdown amount.
  ///         If the loan is in the Funding state, then the loan will be permanently
  ///         transitioned to the DrawdownPeriod state.
  function drawdown(CallableCreditLine storage cl, uint256 amount) internal {
    LoanPhase _loanPhase = cl.loanPhase();
    if (_loanPhase == LoanPhase.Funding) {
      cl._paymentSchedule.startAt(block.timestamp);
      cl._lastFullPaymentTime = block.timestamp;
      cl._checkpointedAsOf = block.timestamp;
      _loanPhase = cl.loanPhase();
      emit DepositsLocked(address(this));
    }
    if (_loanPhase != LoanPhase.DrawdownPeriod) {
      revert ICallableLoanErrors.InvalidLoanPhase(_loanPhase, LoanPhase.DrawdownPeriod);
    }

    if (amount > cl.totalPrincipalPaid()) {
      revert ICallableLoanErrors.DrawdownAmountExceedsDeposits(amount, cl.totalPrincipalPaid());
    }
    cl._waterfall.drawdown(amount);
  }

  function submitCall(
    CallableCreditLine storage cl,
    uint256 amount
  )
    internal
    returns (
      uint256 principalDepositedMoved,
      uint256 principalPaidMoved,
      uint256 principalReservedMoved,
      uint256 interestMoved
    )
  {
    if (cl.loanPhase() != LoanPhase.InProgress) {
      revert ICallableLoanErrors.InvalidLoanPhase(cl.loanPhase(), LoanPhase.InProgress);
    }

    uint256 activeCallTranche = cl.activeCallSubmissionTrancheIndex();
    if (activeCallTranche >= cl.uncalledCapitalTrancheIndex()) {
      revert ICallableLoanErrors.TooLateToSubmitCallRequests();
    }
    if (cl.inLockupPeriod()) {
      revert ICallableLoanErrors.CannotSubmitCallInLockupPeriod();
    }
    return cl._waterfall.move(amount, activeCallTranche);
  }

  function deposit(CallableCreditLine storage cl, uint256 amount) internal {
    LoanPhase _loanPhase = cl.loanPhase();
    if (_loanPhase != LoanPhase.Funding) {
      revert ICallableLoanErrors.InvalidLoanPhase(_loanPhase, LoanPhase.Funding);
    }

    // !! Make assumption that Funding phase deposits are solely in the uncalled capital tranche.
    if (
      amount + cl._waterfall.getTranche(cl.uncalledCapitalTrancheIndex()).principalDeposited() >
      cl.limit()
    ) {
      revert ICallableLoanErrors.DepositExceedsLimit(
        amount,
        cl._waterfall.totalPrincipalDeposited(),
        cl.limit()
      );
    }
    cl._waterfall.deposit(amount);
  }

  /// Withdraws funds from the specified tranche.
  function withdraw(CallableCreditLine storage cl, uint256 amount) internal {
    if (cl.loanPhase() != LoanPhase.Funding) {
      revert ICallableLoanErrors.InvalidLoanPhase(cl.loanPhase(), LoanPhase.Funding);
    }
    cl._waterfall.withdraw(amount);
  }

  /// Settles payment reserves and updates the checkpointed values.
  function checkpoint(CallableCreditLine storage cl) internal {
    if (cl.loanPhase() == LoanPhase.Funding || cl.loanPhase() == LoanPhase.Prefunding) {
      cl._checkpointedAsOf = block.timestamp;
      return;
    }

    cl._lastFullPaymentTime = cl.lastFullPaymentTime();

    /// !! IMPORTANT !!
    /// The order of these assignments matter!
    /// Calculating cl.previewTotalInterestOwed() depends on the value of cl._totalInterestAccruedAtLastCheckpoint.
    /// _totalInterestOwedAtLastCheckpoint must use the ORIGINAL value of _totalInterestAccruedAtLastCheckpoint!
    /// Otherwise cl.previewTotalInterestOwed() (and thus cl._totalInterestOwedAtLastCheckpoint) will be incorrect.
    cl._totalInterestOwedAtLastCheckpoint = cl.previewTotalInterestOwed();
    cl._totalInterestAccruedAtLastCheckpoint = cl.previewTotalInterestAccrued();

    uint256 currentlyActivePrincipalPeriod = cl._paymentSchedule.currentPrincipalPeriod();
    uint256 activePrincipalPeriodAtLastCheckpoint = cl._paymentSchedule.principalPeriodAt(
      cl._checkpointedAsOf
    );

    if (currentlyActivePrincipalPeriod > activePrincipalPeriodAtLastCheckpoint) {
      cl._waterfall.settleReserves(currentlyActivePrincipalPeriod);
    }

    cl._checkpointedAsOf = block.timestamp;
  }

  function setFundableAt(CallableCreditLine storage cl, uint256 newFundableAt) internal {
    if (cl.loanPhase() != LoanPhase.Prefunding) {
      revert ICallableLoanErrors.CannotSetFundableAtAfterFundableAt(cl._fundableAt);
    }
    cl._fundableAt = newFundableAt;
  }

  /*================================================================================
  Main View Functions
  ================================================================================*/
  function loanPhase(CallableCreditLine storage cl) internal view returns (LoanPhase) {
    if (!cl._paymentSchedule.isActive()) {
      return block.timestamp < cl._fundableAt ? LoanPhase.Prefunding : LoanPhase.Funding;
    } else if (block.timestamp < cl.termStartTime() + cl._config.getDrawdownPeriodInSeconds()) {
      return LoanPhase.DrawdownPeriod;
    } else {
      return LoanPhase.InProgress;
    }
  }

  function numLockupPeriods(CallableCreditLine storage cl) internal view returns (uint256) {
    return cl._numLockupPeriods;
  }

  function uncalledCapitalTrancheIndex(
    CallableCreditLine storage cl
  ) internal view returns (uint256) {
    return cl._waterfall.uncalledCapitalTrancheIndex();
  }

  function principalOwedAt(
    CallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256 returnedPrincipalOwed) {
    return
      cl.totalPrincipalOwedAt(timestamp).saturatingSub(
        cl._waterfall.totalPrincipalPaidAfterSettlementUpToTranche(
          cl.trancheIndexAtTimestamp(timestamp)
        )
      );
  }

  function principalOwed(CallableCreditLine storage cl) internal view returns (uint256) {
    return cl.principalOwedAt(block.timestamp);
  }

  function totalPrincipalOwed(CallableCreditLine storage cl) internal view returns (uint256) {
    return cl.totalPrincipalOwedAt(block.timestamp);
  }

  function totalPrincipalOwedAt(
    CallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256) {
    return cl._waterfall.totalPrincipalDepositedUpToTranche(cl.trancheIndexAtTimestamp(timestamp));
  }

  function totalPrincipalPaid(CallableCreditLine storage cl) internal view returns (uint256) {
    return cl.totalPrincipalPaidAt(block.timestamp);
  }

  /// Calculates total interest owed at a given timestamp.
  /// IT: Invalid timestamp - timestamp must be after the last checkpoint.

  function totalInterestOwedAt(
    CallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256) {
    if (timestamp < cl._checkpointedAsOf) {
      revert ICallableLoanErrors.InputTimestampBeforeCheckpoint(timestamp, cl._checkpointedAsOf);
    }
    // After loan maturity there is no concept of additional interest. All interest accrued
    // automatically becomes interest owed.
    if (timestamp > cl.termEndTime()) {
      return cl.totalInterestAccruedAt(timestamp);
    }

    uint256 lastInterestDueTimeAtTimestamp = cl._paymentSchedule.previousInterestDueTimeAt(
      timestamp
    );

    if (lastInterestDueTimeAtTimestamp <= cl._checkpointedAsOf) {
      return cl._totalInterestOwedAtLastCheckpoint;
    } else {
      return cl.totalInterestAccruedAt(lastInterestDueTimeAtTimestamp);
    }
  }

  /// Calculates total interest owed at a given timestamp.
  /// Assumes that principal outstanding is constant from now until the given `timestamp`.
  /// @notice IT: Invalid timestamp
  function interestOwedAt(
    CallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256) {
    if (timestamp < cl._checkpointedAsOf) {
      revert ICallableLoanErrors.InputTimestampBeforeCheckpoint(timestamp, cl._checkpointedAsOf);
    }
    return cl.totalInterestOwedAt(timestamp).saturatingSub(cl.totalInterestPaid());
  }

  /// Interest accrued up to `timestamp`
  /// PT: Past timestamp - timestamp must be now or in the future.
  function interestAccruedAt(
    CallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256) {
    if (timestamp < block.timestamp) {
      revert ICallableLoanErrors.InputTimestampInThePast(timestamp);
    }
    return
      cl.totalInterestAccruedAt(timestamp).saturatingSub(
        Math.max(cl._waterfall.totalInterestPaid(), cl.totalInterestOwedAt(timestamp))
      );
  }

  /* Test cases
   *S = Start B = Buffer Applied At L = Late Fees Start At E = End
   *SBLE
   *SBEL
   *SLEB
   *SLBE
   *SELB
   *SEBL

   *LSEB
   *LSBE
   */

  /// Calculates interest accrued over the duration bounded by the `cl._checkpointedAsOf` and `timestamp` timestamps.
  /// Assumes cl._waterfall.totalPrincipalOutstanding() for the principal balance that the interest is applied to.
  /// Assumes a checkpoint has occurred.
  /// If a checkpoint has not occurred, late fees will not account for balance settlement or future payments.
  /// Late fees should be applied to interest accrued up until block.timestamp.
  /// Should not account for late fees in interest which will accrue in the future as payments could occur.
  function totalInterestAccruedAt(
    CallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256 totalInterestAccruedReturned) {
    if (timestamp < cl._checkpointedAsOf) {
      revert ICallableLoanErrors.InputTimestampBeforeCheckpoint(timestamp, cl._checkpointedAsOf);
    }

    if (!cl._paymentSchedule.isActive()) {
      return 0;
    }

    totalInterestAccruedReturned = cl._totalInterestAccruedAtLastCheckpoint;

    uint256 firstInterestEndPoint = timestamp;
    if (cl._checkpointedAsOf < cl.termEndTime()) {
      firstInterestEndPoint = Math.min(
        cl._paymentSchedule.nextPrincipalDueTimeAt(cl._checkpointedAsOf),
        timestamp
      );
    }

    // Late fees are already accounted for as of _checkpointedAsOf
    // Late fees are already accounted for in _totalInterestAccruedAtLastCheckpoint
    uint256 lateFeesStartAt = Math.max(
      cl._checkpointedAsOf,
      cl._paymentSchedule.nextDueTimeAt(cl._lastFullPaymentTime) +
        (cl._config.getLatenessGracePeriodInDays() * (SECONDS_PER_DAY))
    );

    // Calculate interest accrued before balances are settled.
    totalInterestAccruedReturned += CallableLoanAccountant.calculateInterest(
      cl._checkpointedAsOf,
      firstInterestEndPoint,
      lateFeesStartAt,
      block.timestamp,
      cl._waterfall.totalPrincipalOutstandingBeforeReserves(),
      cl._interestApr,
      cl._lateAdditionalApr
    );

    if (firstInterestEndPoint < timestamp) {
      // Calculate interest accrued after balances are settled.
      totalInterestAccruedReturned += CallableLoanAccountant.calculateInterest(
        firstInterestEndPoint,
        timestamp,
        lateFeesStartAt,
        block.timestamp,
        cl._waterfall.totalPrincipalOutstandingAfterReserves(),
        cl._interestApr,
        cl._lateAdditionalApr
      );
    }
  }

  function totalPrincipalPaidAt(
    CallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256 principalPaidSum) {
    principalPaidSum = cl._waterfall.totalPrincipalPaid();

    if (!cl.isActive()) {
      return principalPaidSum;
    }

    uint256 trancheIndexAtGivenTimestamp = cl.trancheIndexAtTimestamp(timestamp);

    /// If we entered a new principal period since checkpoint,
    /// we should settle reserved principal in the uncalled tranche.
    if (trancheIndexAtGivenTimestamp > cl.trancheIndexAtTimestamp(cl._checkpointedAsOf)) {
      principalPaidSum += cl
        ._waterfall
        .getTranche(cl.uncalledCapitalTrancheIndex())
        .principalReserved();
    }

    // Unsettled principal from previous call request periods which will settle.
    principalPaidSum += cl._waterfall.totalPrincipalReservedUpToTranche(
      Math.min(trancheIndexAtGivenTimestamp, cl.uncalledCapitalTrancheIndex())
    );
  }

  function lastFullPaymentTime(
    CallableCreditLine storage cl
  ) internal view returns (uint256 fullPaymentTime) {
    if (cl.loanPhase() != LoanPhase.InProgress) {
      // The loan has not begun && paymentSchedule calls will revert.
      return block.timestamp;
    }

    fullPaymentTime = cl._lastFullPaymentTime;

    uint256 startPeriod = cl._paymentSchedule.periodAt(
      Math.max(cl._checkpointedAsOf, fullPaymentTime)
    );
    uint256 currentlyActivePeriod = cl._paymentSchedule.currentPeriod();

    for (uint256 periodIndex = startPeriod; periodIndex < currentlyActivePeriod; periodIndex++) {
      uint256 periodEndTime = cl._paymentSchedule.periodEndTime(periodIndex);

      if (cl.principalOwedAt(periodEndTime) == 0 && cl.interestOwedAt(periodEndTime) == 0) {
        fullPaymentTime = periodEndTime;
      } else {
        // If we hit a period where there is still principal or interest owed, we can stop.
        break;
      }
    }
  }

  function isLate(CallableCreditLine storage cl) internal view returns (bool) {
    return cl.isLate(block.timestamp);
  }

  function isLate(CallableCreditLine storage cl, uint256 timestamp) internal view returns (bool) {
    if (
      cl.loanPhase() != LoanPhase.InProgress ||
      ((cl.principalOwedAt(timestamp) + cl.interestOwedAt(timestamp)) == 0)
    ) {
      return false;
    }

    uint256 oldestUnpaidDueTime = cl._paymentSchedule.nextDueTimeAt(cl.lastFullPaymentTime());
    return timestamp > oldestUnpaidDueTime;
  }

  /// Returns the total amount of principal outstanding - after applying reserved principal.
  function totalPrincipalOutstanding(
    CallableCreditLine storage cl
  ) internal view returns (uint256) {
    return cl._waterfall.totalPrincipalOutstandingAfterReserves();
  }

  /// @notice Returns the tranche index which the given timestamp falls within.
  /// @return The tranche index will go 1 beyond the max tranche index to represent the "after loan" period.
  ///         This is not to be confused with activeCallSubmissionTrancheIndex, which is the tranche for which
  ///         current call requests should be submitted to.
  ///         See notes.md for explanation of relationship between principalPeriod, call request period and tranche.
  function trancheIndexAtTimestamp(
    CallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256) {
    return cl._paymentSchedule.principalPeriodAt(timestamp);
  }

  /// Returns the index of the tranche which current call requests should be submitted to.
  ///See notes.md for explanation of relationship between principalPeriod, call request period and tranche.
  function activeCallSubmissionTrancheIndex(
    CallableCreditLine storage cl
  ) internal view returns (uint256 activeTrancheIndex) {
    uint256 currentTranche = cl.trancheIndexAtTimestamp(block.timestamp);
    // Call requests submitted in the current principal period's lockup period are
    // submitted into the tranche of the NEXT principal period
    return cl.inLockupPeriod() ? currentTranche + 1 : currentTranche;
  }

  /// Returns the balances of the given tranche - only settling principal if the tranche should be settled.
  function getSettledTrancheInfo(
    CallableCreditLine storage cl,
    uint256 trancheId
  ) internal view returns (SettledTrancheInfo memory settledTrancheInfo) {
    Tranche storage tranche = cl._waterfall.getTranche(trancheId);
    settledTrancheInfo.interestPaid = tranche.interestPaid();
    settledTrancheInfo.principalDeposited = tranche.principalDeposited();

    bool useSettledPrincipal;

    if (cl.isActive()) {
      if (trancheId == cl.uncalledCapitalTrancheIndex()) {
        uint256 currentlyActivePrincipalPeriod = cl._paymentSchedule.currentPrincipalPeriod();
        uint256 activePrincipalPeriodAtLastCheckpoint = cl._paymentSchedule.principalPeriodAt(
          cl._checkpointedAsOf
        );
        useSettledPrincipal =
          currentlyActivePrincipalPeriod > activePrincipalPeriodAtLastCheckpoint;
      } else {
        useSettledPrincipal = trancheId < cl._paymentSchedule.currentPrincipalPeriod();
      }
    }

    if (useSettledPrincipal) {
      settledTrancheInfo.principalPaid = tranche.principalPaid() + tranche.principalReserved();
      settledTrancheInfo.principalReserved = 0;
    } else {
      settledTrancheInfo.principalPaid = tranche.principalPaid();
      settledTrancheInfo.principalReserved = tranche.principalReserved();
    }
  }

  function totalInterestPaid(CallableCreditLine storage cl) internal view returns (uint256) {
    return cl._waterfall.totalInterestPaid();
  }

  function totalPrincipalDeposited(CallableCreditLine storage cl) internal view returns (uint256) {
    return cl._waterfall.totalPrincipalDeposited();
  }

  function inLockupPeriod(CallableCreditLine storage cl) internal view returns (bool) {
    uint256 currentPeriod = cl._paymentSchedule.currentPeriod();
    uint256 numPeriodsPerPrincipalPeriod = cl._paymentSchedule.periodsPerPrincipalPeriod();
    return
      currentPeriod % numPeriodsPerPrincipalPeriod >=
      numPeriodsPerPrincipalPeriod - cl._numLockupPeriods;
  }

  /*================================================================================
  Payment Schedule Proxy Functions
  ================================================================================*/

  function isActive(CallableCreditLine storage cl) internal view returns (bool) {
    return cl._paymentSchedule.isActive();
  }

  function withinPrincipalGracePeriod(CallableCreditLine storage cl) internal view returns (bool) {
    return cl._paymentSchedule.withinPrincipalGracePeriodAt(block.timestamp);
  }

  function nextPrincipalDueTime(CallableCreditLine storage cl) internal view returns (uint256) {
    return cl.nextPrincipalDueTimeAt(block.timestamp);
  }

  function nextPrincipalDueTimeAt(
    CallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256) {
    return cl._paymentSchedule.nextPrincipalDueTimeAt(timestamp);
  }

  function nextInterestDueTimeAt(
    CallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256) {
    return cl._paymentSchedule.nextInterestDueTimeAt(timestamp);
  }

  function nextDueTime(CallableCreditLine storage cl) internal view returns (uint256) {
    return cl.nextDueTimeAt(block.timestamp);
  }

  function nextDueTimeAt(
    CallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256) {
    return cl._paymentSchedule.nextDueTimeAt(timestamp);
  }

  function termStartTime(CallableCreditLine storage cl) internal view returns (uint256) {
    return cl._paymentSchedule.termStartTime();
  }

  function termEndTime(CallableCreditLine storage cl) internal view returns (uint256) {
    return cl._paymentSchedule.termEndTime();
  }

  /*================================================================================
  Static Struct Config Getters
  ================================================================================*/
  function fundableAt(CallableCreditLine storage cl) internal view returns (uint256) {
    return cl._fundableAt;
  }

  function interestApr(CallableCreditLine storage cl) internal view returns (uint256) {
    return cl._interestApr;
  }

  function lateAdditionalApr(CallableCreditLine storage cl) internal view returns (uint256) {
    return cl._lateAdditionalApr;
  }

  function limit(CallableCreditLine storage cl) internal view returns (uint256) {
    return cl._limit;
  }

  function checkpointedAsOf(CallableCreditLine storage cl) internal view returns (uint256) {
    return cl._checkpointedAsOf;
  }

  event DepositsLocked(address indexed loan);
}

/// @notice Functions which make no assumption that a checkpoint has just occurred.
library PreviewCallableCreditLineLogic {
  function previewProportionalInterestAndPrincipalAvailable(
    CallableCreditLine storage cl,
    uint256 trancheId,
    uint256 principal,
    uint256 feePercent
  ) internal view returns (uint256, uint256) {
    Tranche storage tranche = cl._waterfall.getTranche(trancheId);
    if (cl.loanPhase() != LoanPhase.InProgress) {
      return tranche.proportionalInterestAndPrincipalAvailable(principal, feePercent);
    }
    bool uncalledTrancheAndNeedsSettling = trancheId == cl.uncalledCapitalTrancheIndex() &&
      cl.trancheIndexAtTimestamp(cl._checkpointedAsOf) <
      cl._paymentSchedule.currentPrincipalPeriod();
    bool callRequestTrancheAndNeedsSettling = trancheId < cl.uncalledCapitalTrancheIndex() &&
      trancheId < cl._paymentSchedule.currentPrincipalPeriod();
    bool needsSettling = uncalledTrancheAndNeedsSettling || callRequestTrancheAndNeedsSettling;

    return
      needsSettling
        ? tranche.proportionalInterestAndPrincipalAvailableAfterReserves(principal, feePercent)
        : tranche.proportionalInterestAndPrincipalAvailable(principal, feePercent);
  }

  function previewProportionalCallablePrincipal(
    CallableCreditLine storage cl,
    uint256 trancheId,
    uint256 principalDeposited
  ) internal view returns (uint256) {
    uint256 currentlyActivePrincipalPeriod = cl._paymentSchedule.currentPrincipalPeriod();
    uint256 activePrincipalPeriodAtLastCheckpoint = cl._paymentSchedule.principalPeriodAt(
      cl._checkpointedAsOf
    );
    if (currentlyActivePrincipalPeriod > activePrincipalPeriodAtLastCheckpoint) {
      return
        cl._waterfall.getTranche(trancheId).proportionalPrincipalOutstandingAfterReserves(
          principalDeposited
        );
    } else {
      return
        cl._waterfall.getTranche(trancheId).proportionalPrincipalOutstandingBeforeReserves(
          principalDeposited
        );
    }
  }

  /// Returns the total interest owed less total interest paid
  function previewInterestOwed(CallableCreditLine storage cl) internal view returns (uint256) {
    return cl.interestOwedAt(block.timestamp);
  }

  /// Returns the total interest owed
  function previewTotalInterestOwed(CallableCreditLine storage cl) internal view returns (uint256) {
    return cl.totalInterestOwedAt(block.timestamp);
  }

  /// Interest accrued up to now minus the max(totalInterestPaid, totalInterestOwedAt)
  function previewInterestAccrued(CallableCreditLine storage cl) internal view returns (uint256) {
    return cl.interestAccruedAt(block.timestamp);
  }

  /// Returns the total interest accrued
  function previewTotalInterestAccrued(
    CallableCreditLine storage cl
  ) internal view returns (uint256) {
    return cl.totalInterestAccruedAt(block.timestamp);
  }
}

/// @notice Functions which assume a checkpoint has just occurred.
library CheckpointedCallableCreditLineLogic {
  using SaturatingSub for uint256;

  function totalInterestOwed(CallableCreditLine storage cl) internal view returns (uint256) {
    assert(cl._checkpointedAsOf == block.timestamp);
    return cl._totalInterestOwedAtLastCheckpoint;
  }

  function totalInterestAccrued(CallableCreditLine storage cl) internal view returns (uint256) {
    assert(cl._checkpointedAsOf == block.timestamp);
    return cl._totalInterestAccruedAtLastCheckpoint;
  }

  function proportionalCallablePrincipal(
    CallableCreditLine storage cl,
    uint256 trancheId,
    uint256 principalDeposited
  ) internal view returns (uint256) {
    return
      cl._waterfall.getTranche(trancheId).proportionalPrincipalOutstandingBeforeReserves(
        principalDeposited
      );
  }

  function proportionalInterestAndPrincipalAvailable(
    CallableCreditLine storage cl,
    uint256 trancheId,
    uint256 principal,
    uint256 feePercent
  ) internal view returns (uint256, uint256) {
    assert(cl._checkpointedAsOf == block.timestamp);
    Tranche storage tranche = cl._waterfall.getTranche(trancheId);
    return tranche.proportionalInterestAndPrincipalAvailable(principal, feePercent);
  }

  /// Returns the total interest owed less total interest paid
  function interestOwed(CallableCreditLine storage cl) internal view returns (uint256) {
    assert(cl._checkpointedAsOf == block.timestamp);
    return cl._totalInterestOwedAtLastCheckpoint.saturatingSub(cl.totalInterestPaid());
  }

  /// Interest accrued up to now minus the max(totalInterestPaid, totalInterestOwedAt)
  function interestAccrued(CallableCreditLine storage cl) internal view returns (uint256) {
    assert(cl._checkpointedAsOf == block.timestamp);
    return
      cl._totalInterestAccruedAtLastCheckpoint.saturatingSub(
        Math.max(cl._waterfall.totalInterestPaid(), cl._totalInterestOwedAtLastCheckpoint)
      );
  }
}