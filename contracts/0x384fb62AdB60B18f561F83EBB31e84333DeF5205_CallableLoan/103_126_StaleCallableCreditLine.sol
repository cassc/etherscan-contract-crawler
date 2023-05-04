// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {ISchedule} from "../../../../interfaces/ISchedule.sol";
import {IGoldfinchConfig} from "../../../../interfaces/IGoldfinchConfig.sol";
import {LoanPhase} from "../../../../interfaces/ICallableLoan.sol";
import {Waterfall} from "./Waterfall.sol";
// solhint-disable-next-line max-line-length
import {CallableCreditLine, CallableCreditLineLogic, PreviewCallableCreditLineLogic, SettledTrancheInfo} from "./CallableCreditLine.sol";
import {PaymentSchedule, PaymentScheduleLogic} from "../../schedule/PaymentSchedule.sol";

struct StaleCallableCreditLine {
  CallableCreditLine _cl;
}

using StaleCallableCreditLineLogic for StaleCallableCreditLine global;

/**
 * Simple wrapper around CallableCreditLine which returns a checkpointed
 * CallableCreditLine after checkpoint() is called.
 */
library StaleCallableCreditLineLogic {
  using PreviewCallableCreditLineLogic for CallableCreditLine;

  function initialize(
    StaleCallableCreditLine storage cl,
    IGoldfinchConfig _config,
    uint256 _fundableAt,
    uint256 _numLockupPeriods,
    ISchedule _schedule,
    uint256 _interestApr,
    uint256 _lateAdditionalApr,
    uint256 _limit
  ) internal {
    cl._cl.initialize({
      _config: _config,
      _fundableAt: _fundableAt,
      _numLockupPeriods: _numLockupPeriods,
      _schedule: _schedule,
      _interestApr: _interestApr,
      _lateAdditionalApr: _lateAdditionalApr,
      _limit: _limit
    });
  }

  function checkpoint(
    StaleCallableCreditLine storage cl
  ) internal returns (CallableCreditLine storage) {
    cl._cl.checkpoint();
    return cl._cl;
  }

  function schedule(StaleCallableCreditLine storage cl) internal view returns (ISchedule) {
    return cl._cl._paymentSchedule.schedule;
  }

  function termStartTime(StaleCallableCreditLine storage cl) internal view returns (uint256) {
    return cl._cl.termStartTime();
  }

  function lastFullPaymentTime(StaleCallableCreditLine storage cl) internal view returns (uint256) {
    return cl._cl.lastFullPaymentTime();
  }

  function fundableAt(StaleCallableCreditLine storage cl) internal view returns (uint256) {
    return cl._cl.fundableAt();
  }

  function limit(StaleCallableCreditLine storage cl) internal view returns (uint256) {
    return cl._cl.limit();
  }

  function interestApr(StaleCallableCreditLine storage cl) internal view returns (uint256) {
    return cl._cl.interestApr();
  }

  function lateAdditionalApr(StaleCallableCreditLine storage cl) internal view returns (uint256) {
    return cl._cl.lateAdditionalApr();
  }

  function isLate(StaleCallableCreditLine storage cl) internal view returns (bool) {
    return cl._cl.isLate();
  }

  function loanPhase(StaleCallableCreditLine storage cl) internal view returns (LoanPhase) {
    return cl._cl.loanPhase();
  }

  function checkpointedAsOf(StaleCallableCreditLine storage cl) internal view returns (uint256) {
    return cl._cl.checkpointedAsOf();
  }

  function numLockupPeriods(StaleCallableCreditLine storage cl) internal view returns (uint256) {
    return cl._cl.numLockupPeriods();
  }

  function inLockupPeriod(StaleCallableCreditLine storage cl) internal view returns (bool) {
    return cl._cl.inLockupPeriod();
  }

  /// @notice If a checkpoint has not occurred, late fees may be overestimated beyond the next due time.
  function interestOwed(StaleCallableCreditLine storage cl) internal view returns (uint256) {
    return cl._cl.previewInterestOwed();
  }

  function principalOwed(StaleCallableCreditLine storage cl) internal view returns (uint256) {
    return cl._cl.principalOwed();
  }

  /// @notice If a checkpoint has not occurred, late fees may be overestimated beyond the next due time.
  function interestOwedAt(
    StaleCallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256) {
    return cl._cl.interestOwedAt(timestamp);
  }

  function principalOwedAt(
    StaleCallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256) {
    return cl._cl.principalOwedAt(timestamp);
  }

  /// @notice If a checkpoint has not occurred, late fees may be overestimated beyond the next due time.
  function totalInterestOwedAt(
    StaleCallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256) {
    return cl._cl.totalInterestOwedAt(timestamp);
  }

  function totalPrincipalOwedAt(
    StaleCallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256) {
    return cl._cl.totalPrincipalOwedAt(timestamp);
  }

  /// @notice If a checkpoint has not occurred, late fees may be overestimated beyond the next due time.
  function totalInterestOwed(StaleCallableCreditLine storage cl) internal view returns (uint256) {
    return cl._cl.previewTotalInterestOwed();
  }

  function totalPrincipalDeposited(
    StaleCallableCreditLine storage cl
  ) internal view returns (uint256) {
    return cl._cl.totalPrincipalDeposited();
  }

  function totalPrincipalOwed(StaleCallableCreditLine storage cl) internal view returns (uint256) {
    return cl._cl.totalPrincipalOwed();
  }

  function totalPrincipalOutstanding(
    StaleCallableCreditLine storage cl
  ) internal view returns (uint256) {
    return cl._cl.totalPrincipalOutstanding();
  }

  // Currently unused
  // function totalPrincipalOutstandingBeforeReserves(
  //   StaleCallableCreditLine storage cl
  // ) internal view returns (uint256) {
  //   return cl._cl.totalPrincipalOutstandingBeforeReserves();
  // }

  function nextInterestDueTimeAt(
    StaleCallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256) {
    return cl._cl.nextInterestDueTimeAt(timestamp);
  }

  function nextPrincipalDueTime(
    StaleCallableCreditLine storage cl
  ) internal view returns (uint256) {
    return cl._cl.nextPrincipalDueTime();
  }

  // Currently unused
  // function nextPrincipalDueTimeAt(
  //   StaleCallableCreditLine storage cl,
  //   uint256 timestamp
  // ) internal view returns (uint256) {
  //   return cl._cl.nextPrincipalDueTimeAt(timestamp);
  // }

  function nextDueTimeAt(
    StaleCallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256) {
    return cl._cl.nextDueTimeAt(timestamp);
  }

  function nextDueTime(StaleCallableCreditLine storage cl) internal view returns (uint256) {
    return cl._cl.nextDueTime();
  }

  function termEndTime(StaleCallableCreditLine storage cl) internal view returns (uint256) {
    return cl._cl.termEndTime();
  }

  function proportionalCallablePrincipal(
    StaleCallableCreditLine storage cl,
    uint256 trancheId,
    uint256 principalDeposited
  ) internal view returns (uint256) {
    return cl._cl.previewProportionalCallablePrincipal(trancheId, principalDeposited);
  }

  function proportionalInterestAndPrincipalAvailable(
    StaleCallableCreditLine storage cl,
    uint256 trancheId,
    uint256 principal,
    uint256 feePercent
  ) internal view returns (uint256, uint256) {
    return
      cl._cl.previewProportionalInterestAndPrincipalAvailable({
        trancheId: trancheId,
        principal: principal,
        feePercent: feePercent
      });
  }

  /// @notice If a checkpoint has not occurred, late fees may be overestimated beyond the next due time.
  function totalInterestAccrued(
    StaleCallableCreditLine storage cl
  ) internal view returns (uint256) {
    return cl._cl.previewTotalInterestAccrued();
  }

  /// @notice If a checkpoint has not occurred, late fees may be overestimated beyond the next due time.
  function totalInterestAccruedAt(
    StaleCallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256) {
    return cl._cl.totalInterestAccruedAt(timestamp);
  }

  /// @notice If a checkpoint has not occurred, late fees may be overestimated beyond the next due time.
  function interestAccrued(StaleCallableCreditLine storage cl) internal view returns (uint256) {
    return cl._cl.previewInterestAccrued();
  }

  /// @notice If a checkpoint has not occurred, late fees may be overestimated beyond the next due time.
  function interestAccruedAt(
    StaleCallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256) {
    return cl._cl.interestAccruedAt(timestamp);
  }

  function totalInterestPaid(StaleCallableCreditLine storage cl) internal view returns (uint256) {
    return cl._cl.totalInterestPaid();
  }

  function totalPrincipalPaidAt(
    StaleCallableCreditLine storage cl,
    uint256 timestamp
  ) internal view returns (uint256) {
    return cl._cl.totalPrincipalPaidAt(timestamp);
  }

  function totalPrincipalPaid(StaleCallableCreditLine storage cl) internal view returns (uint256) {
    return cl._cl.totalPrincipalPaid();
  }

  function withinPrincipalGracePeriod(
    StaleCallableCreditLine storage cl
  ) internal view returns (bool) {
    return cl._cl.withinPrincipalGracePeriod();
  }

  function uncalledCapitalTrancheIndex(
    StaleCallableCreditLine storage cl
  ) internal view returns (uint256) {
    return cl._cl.uncalledCapitalTrancheIndex();
  }

  function getSettledTrancheInfo(
    StaleCallableCreditLine storage cl,
    uint256 trancheId
  ) internal view returns (SettledTrancheInfo memory) {
    return cl._cl.getSettledTrancheInfo(trancheId);
  }
}