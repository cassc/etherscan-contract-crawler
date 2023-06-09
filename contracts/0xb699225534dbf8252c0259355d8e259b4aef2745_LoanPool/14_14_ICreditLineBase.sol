// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICreditLineBase {
  /// @notice State of the loan
  /// @param Funding loan is currently fundraising from lenders
  /// @param Refund funding failed, funds to be returned to lenders, terminal state
  /// @param Repayment loan has been drawndown and borrower is repaying the loan
  /// @param Repaid loan has been fully repaid by borrower, terminal state
  enum State {
    Funding,
    Refund,
    Repayment,
    Repaid
  }

  /// @notice When a function is executed under the wrong loan state
  /// @param expectedState State that the loan should be in for the function to execute
  /// @param currentState State that the loan is currently in
  error IncorrectState(State expectedState, State currentState);

  /// @notice Funding exceeds the max limit
  error MaxLimitExceeded();

  /// @notice Loan state of the credit line has been updated
  /// @param newState State of the loan after the update
  event LoanStateUpdate(State indexed newState);

  /// @notice Repayment has been made towards loan
  /// @param timestamp Timestamp of repayment
  /// @param amount Amount of repayment
  /// @param interestRepaid Payment towards interest
  /// @param principalRepaid Payment towards principal
  /// @param additionalRepayment Excess payments
  event Repayment(
    uint256 timestamp,
    uint256 amount,
    uint256 interestRepaid,
    uint256 principalRepaid,
    uint256 additionalRepayment
  );

  function maxLimit() external view returns (uint256);

  function interestApr() external view returns (uint256);

  function paymentPeriod() external view returns (uint256);

  function gracePeriod() external view returns (uint256);

  function lateFeeApr() external view returns (uint256);

  function earlyRepaymentFee() external view returns (uint256);

  function principalBalance() external view returns (uint256);

  function interestBalance() external view returns (uint256);

  function totalPrincipalRepaid() external view returns (uint256);

  function totalInterestRepaid() external view returns (uint256);

  function totalEarlyFeePaid() external view returns (uint256);

  function additionalRepayment() external view returns (uint256);

  function lateInterestAccrued() external view returns (uint256);

  function interestAccruedAsOf() external view returns (uint256);

  function lastFullPaymentTime() external view returns (uint256);

  function minPaymentPerPeriod() external view returns (uint256);

  function loanStartTime() external view returns (uint256);

  function loanTenureInPeriods() external view returns (uint256);

  function loanState() external view returns (State);

  function initialize(
    uint256 _maxLimit,
    uint256 _interestApr,
    uint256 _paymentPeriod,
    uint256 _gracePeriod,
    uint256 _lateFeeApr,
    uint256 _loanTenureInPeriods,
    uint256 _earlyRepaymentFee
  ) external;

  function fund(uint256 amount) external;

  function drawdown() external returns (uint256 amount);

  function refund() external;

  function repay(
    uint256 amount
  )
    external
    returns (
      uint256 interestPayment,
      uint256 principalPayment,
      uint256 earlyFeePayment,
      uint256 additionalBalancePayment
    );

  function allocatePayment(
    uint256 amount,
    uint256 interestOutstanding,
    uint256 principalOutstanding,
    uint256 paymentExpected
  )
    external
    view
    returns (
      uint256 interestPayment,
      uint256 principalPayment,
      uint256 earlyFeePayment,
      uint256 additionalBalancePayment
    );

  function paymentDue() external view returns (uint256 amount);

  function interestAccruedSinceLastAssessed()
    external
    view
    returns (
      uint256 interestOwed,
      uint256 lateInterestOwed,
      uint256 fullPeriodsElapsed
    );

  function interestAccruedAtTimestamp(
    uint256 timestamp
  )
    external
    view
    returns (
      uint256 interestOwed,
      uint256 lateInterestOwed,
      uint256 fullPeriodsElapsed
    );

  function interestOnBalance(
    uint256 timePeriod
  ) external view returns (uint256 interestOwed);

  function lateInterestOnBalance(
    uint256 timePeriod
  ) external view returns (uint256 interestOwed);

  function totalRepayments() external view returns (uint256 amount);
}