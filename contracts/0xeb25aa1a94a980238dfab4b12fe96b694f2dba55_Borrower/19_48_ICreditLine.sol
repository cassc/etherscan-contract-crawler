// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import {ILoan} from "./ILoan.sol";

import {ICreditLine} from "./ICreditLine.sol";
import {ISchedule} from "./ISchedule.sol";

interface ICreditLine {
  function balance() external view returns (uint256);

  function interestOwed() external view returns (uint256);

  function principalOwed() external view returns (uint256);

  function termEndTime() external view returns (uint256);

  function nextDueTime() external view returns (uint256);

  function interestAccruedAsOf() external view returns (uint256);

  function lastFullPaymentTime() external view returns (uint256);

  function borrower() external view returns (address);

  function currentLimit() external view returns (uint256);

  function limit() external view returns (uint256);

  function maxLimit() external view returns (uint256);

  function interestApr() external view returns (uint256);

  function lateFeeApr() external view returns (uint256);

  function isLate() external view returns (bool);

  function withinPrincipalGracePeriod() external view returns (bool);

  /// @notice Cumulative interest accrued up to now
  function totalInterestAccrued() external view returns (uint256);

  /// @notice Cumulative interest accrued up to `timestamp`
  function totalInterestAccruedAt(uint256 timestamp) external view returns (uint256);

  /// @notice Cumulative interest paid back up to now
  function totalInterestPaid() external view returns (uint256);

  /// @notice Cumulative interest owed up to now
  function totalInterestOwed() external view returns (uint256);

  /// @notice Cumulative interest owed up to `timestamp`
  function totalInterestOwedAt(uint256 timestamp) external view returns (uint256);

  /// @notice Interest that would be owed at `timestamp`
  function interestOwedAt(uint256 timestamp) external view returns (uint256);

  /// @notice Interest accrued in the current payment period up to now. Converted to
  ///   owed interest once we cross into the next payment period. Is 0 if the
  ///   current time is after loan maturity (all interest accrued immediately becomes
  ///   interest owed).
  function interestAccrued() external view returns (uint256);

  /// @notice Interest accrued in the current payment period for `timestamp`. Coverted to
  ///   owed interest once we cross into the payment period after `timestamp`. Is 0
  ///   if `timestamp` is after loan maturity (all interest accrued immediately becomes
  ///   interest owed).
  function interestAccruedAt(uint256 timestamp) external view returns (uint256);

  /// @notice Principal owed up to `timestamp`
  function principalOwedAt(uint256 timestamp) external view returns (uint256);

  /// @notice Returns the total amount of principal thats been paid
  function totalPrincipalPaid() external view returns (uint256);

  /// @notice Cumulative principal owed at timestamp
  function totalPrincipalOwedAt(uint256 timestamp) external view returns (uint256);

  /// @notice Cumulative principal owed at current timestamp
  function totalPrincipalOwed() external view returns (uint256);

  function setLimit(uint256 newAmount) external;

  function setMaxLimit(uint256 newAmount) external;

  /// @notice Time of first drawdown
  function termStartTime() external view returns (uint256);

  /// @notice Process a bulk payment, allocating the payment amount based on the payment waterfall
  function pay(uint paymentAmount) external returns (ILoan.PaymentAllocation memory);

  /**
   * Process a payment according to the waterfall described in `Accountant.allocatePayment`
   * @param principalPayment principal payment amount
   * @param interestPayment interest payment amount
   * @return payment allocation
   */
  function pay(
    uint256 principalPayment,
    uint256 interestPayment
  ) external returns (ILoan.PaymentAllocation memory);

  /// @notice Drawdown on the line
  /// @param amount amount to drawdown. Cannot exceed the line's limit
  function drawdown(uint256 amount) external;
}