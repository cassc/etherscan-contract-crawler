// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
// import {console2 as console} from "forge-std/console2.sol";
import {Tranche} from "./Tranche.sol";
import {ICallableLoanErrors} from "../../../../interfaces/ICallableLoanErrors.sol";

using Math for uint256;
using WaterfallLogic for Waterfall global;

/**
 * @notice Handles the accounting of borrower obligations across all tranches.
 *         Supports
 *         - Deposit of funds (into the uncalled tranche)
 *         - Drawdown of funds  (from the uncalled tranche)
 *         - Repayment of borrowed funds - across all tranches
 *         - Withdrawal of paid funds (from the uncalled tranche)
 *         - Summing accounting variables across all tranches
 *         See "./notes.md" for notes on relationships between struct entities in Callable Loans.
 */

struct Waterfall {
  Tranche[] _tranches;
  uint[31] __padding;
}

library WaterfallLogic {
  /*================================================================================
  Constants
  ================================================================================*/
  uint256 internal constant MINIMUM_WATERFALL_TRANCHES = 2;

  function initialize(Waterfall storage w, uint256 nTranches) internal {
    if (w._tranches.length != 0) {
      revert ICallableLoanErrors.CannotReinitialize();
    }
    if (nTranches < MINIMUM_WATERFALL_TRANCHES) {
      revert ICallableLoanErrors.HasInsufficientTranches(nTranches, MINIMUM_WATERFALL_TRANCHES);
    }
    for (uint256 i = 0; i < nTranches; i++) {
      Tranche memory t;
      w._tranches.push(t);
    }
  }

  /*================================================================================
  Main Write Functions
  ================================================================================*/
  /// @notice apply a payment to tranches in the waterfall.
  ///         The principal payment is applied to the tranches in order of priority
  ///         The interest payment is applied to the tranches pro rata
  /// @param principalAmount: the amount of principal to apply to the tranches
  /// @param interestAmount: the amount of interest to apply to the tranches
  /// @param reserveTranchesIndexStart: After this index (inclusive), tranches will reserve principal
  function pay(
    Waterfall storage w,
    uint256 principalAmount,
    uint256 interestAmount,
    uint256 reserveTranchesIndexStart
  ) internal {
    uint256 _totalPrincipalOutstandingBeforeReserves = w.totalPrincipalOutstandingBeforeReserves();
    if (_totalPrincipalOutstandingBeforeReserves == 0) {
      revert ICallableLoanErrors.NoBalanceToPay(principalAmount);
    }

    // assume that tranches are ordered in priority. First is highest priority
    // NOTE: if we start i at the earliest unpaid tranche/quarter and end at the current quarter
    //        then we skip iterations that would result in a no-op
    uint256 principalLeft = principalAmount;
    uint256 interestLeft = interestAmount;
    for (uint256 i = 0; i < w._tranches.length - 1; i++) {
      Tranche storage tranche = w.getTranche(i);
      uint256 proRataInterestPayment = (interestAmount *
        tranche.principalOutstandingBeforeReserves()) / _totalPrincipalOutstandingBeforeReserves;
      uint256 principalPayment = Math.min(
        tranche.principalOutstandingAfterReserves(),
        principalLeft
      );
      // subtract so that future iterations can't re-allocate a principal payment
      principalLeft -= principalPayment;
      interestLeft -= proRataInterestPayment;
      if (i < reserveTranchesIndexStart) {
        tranche.pay({principalAmount: principalPayment, interestAmount: proRataInterestPayment});
      } else {
        tranche.reserve({
          principalAmount: principalPayment,
          interestAmount: proRataInterestPayment
        });
      }
    }

    // Use remaining interest to avoid USDC integer division precision error.
    {
      uint256 uncalledCapitalTrancheIdx = w.uncalledCapitalTrancheIndex();
      Tranche storage uncalledTranche = w.getTranche(uncalledCapitalTrancheIdx);
      uint256 principalPayment = Math.min(
        uncalledTranche.principalOutstandingAfterReserves(),
        principalLeft
      );
      principalLeft -= principalPayment;
      if (uncalledCapitalTrancheIdx < reserveTranchesIndexStart) {
        uncalledTranche.pay({principalAmount: principalPayment, interestAmount: interestLeft});
      } else {
        uncalledTranche.reserve({principalAmount: principalPayment, interestAmount: interestLeft});
      }
    }

    // Sanity check - CallableLoanAccountant should have already accounted for any excess payment.
    assert(principalLeft == 0);
  }

  function drawdown(Waterfall storage w, uint256 principalAmount) internal {
    Tranche storage tranche = w.getTranche(w.uncalledCapitalTrancheIndex());
    tranche.drawdown(principalAmount);
  }

  /**
   * @notice Move principal and paid interest from one tranche to another
   */
  function move(
    Waterfall storage w,
    uint256 principalOutstanding,
    uint256 toCallRequestPeriodTrancheId
  )
    internal
    returns (
      uint256 principalDeposited,
      uint256 principalPaid,
      uint256 principalReserved,
      uint256 interestPaid
    )
  {
    (principalDeposited, principalPaid, principalReserved, interestPaid) = w
      .getTranche(w.uncalledCapitalTrancheIndex())
      .take(principalOutstanding);

    w.getTranche(toCallRequestPeriodTrancheId).addToBalances(
      principalDeposited,
      principalPaid,
      principalReserved,
      interestPaid
    );
  }

  /**
   * @notice Withdraw principal from the uncalled tranche.
            Assumes that the caller is allowed to withdraw.
   */
  function withdraw(Waterfall storage w, uint256 principalAmount) internal {
    return w.getTranche(w.uncalledCapitalTrancheIndex()).withdraw(principalAmount);
  }

  /**
   * @notice Deposits principal into the uncalled tranche.
            Assumes that the caller is allowed to deposit.
   */
  function deposit(Waterfall storage w, uint256 principalAmount) internal {
    return w.getTranche(w.uncalledCapitalTrancheIndex()).deposit(principalAmount);
  }

  /*================================================================================
  Main View Functions
  ================================================================================*/
  /// Settle all past due tranches as well as the last tranche.
  /// @param currentTrancheIndex - Index of the current tranche. All previous tranches are due.
  function settleReserves(Waterfall storage w, uint256 currentTrancheIndex) internal {
    uint256 uncalledCapitalTrancheIdx = w.uncalledCapitalTrancheIndex();
    Tranche storage uncalledCapitalTranche = w.getTranche(uncalledCapitalTrancheIdx);
    uncalledCapitalTranche.settleReserves();
    for (uint256 i = 0; i < currentTrancheIndex && i < uncalledCapitalTrancheIdx; i++) {
      w._tranches[i].settleReserves();
    }
  }

  function getTranche(
    Waterfall storage w,
    uint256 trancheId
  ) internal view returns (Tranche storage) {
    return w._tranches[trancheId];
  }

  function numTranches(Waterfall storage w) internal view returns (uint256) {
    return w._tranches.length;
  }

  function uncalledCapitalTrancheIndex(Waterfall storage w) internal view returns (uint256) {
    return w.numTranches() - 1;
  }

  /// @notice Returns the total amount of principal paid to all tranches
  function totalPrincipalDeposited(Waterfall storage w) internal view returns (uint256 sum) {
    for (uint256 i = 0; i < w.numTranches(); i++) {
      sum += w.getTranche(i).principalDeposited();
    }
  }

  /// @notice Returns the total amount of interest paid to all tranches
  function totalInterestPaid(Waterfall storage w) internal view returns (uint256 sum) {
    for (uint256 i = 0; i < w.numTranches(); i++) {
      sum += w.getTranche(i).interestPaid();
    }
  }

  /// @notice Returns the total amount of principal paid to all tranches
  function totalPrincipalPaidAfterSettlementUpToTranche(
    Waterfall storage w,
    uint256 trancheIndex
  ) internal view returns (uint256 sum) {
    for (uint256 i = 0; i < trancheIndex; i++) {
      sum += w.getTranche(i).principalPaidAfterSettlement();
    }
  }

  /// @notice Returns the total amount of principal paid to all tranches
  function totalPrincipalPaid(
    Waterfall storage w
  ) internal view returns (uint256 totalPrincipalPaidSum) {
    for (uint256 i = 0; i < w.numTranches(); i++) {
      totalPrincipalPaidSum += w.getTranche(i).principalPaid();
    }
  }

  function totalPrincipalOutstandingBeforeReserves(
    Waterfall storage w
  ) internal view returns (uint256 sum) {
    for (uint256 i = 0; i < w._tranches.length; i++) {
      sum += w.getTranche(i).principalOutstandingBeforeReserves();
    }
  }

  function totalPrincipalOutstandingAfterReserves(
    Waterfall storage w
  ) internal view returns (uint256 sum) {
    for (uint256 i = 0; i < w._tranches.length; i++) {
      sum += w.getTranche(i).principalOutstandingAfterReserves();
    }
  }

  /**
   *
   * @param trancheIndex Exclusive upper bound (i.e. the tranche at this index is not included)
   */
  function totalPrincipalReservedUpToTranche(
    Waterfall storage w,
    uint256 trancheIndex
  ) internal view returns (uint256 sum) {
    for (uint256 i = 0; i < trancheIndex; i++) {
      sum += w.getTranche(i).principalReserved();
    }
  }

  /**
   *
   * @param trancheIndex Exclusive upper bound (i.e. the tranche at this index is not included)
   */
  function totalPrincipalDepositedUpToTranche(
    Waterfall storage w,
    uint256 trancheIndex
  ) internal view returns (uint256 sum) {
    for (uint256 i = 0; i < trancheIndex; i++) {
      sum += w.getTranche(i).principalDeposited();
    }
  }
}