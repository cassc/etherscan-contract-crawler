// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import {ILoan} from "./ILoan.sol";
import {ISchedule} from "./ISchedule.sol";
import {IGoldfinchConfig} from "./IGoldfinchConfig.sol";

/// A LoanPhase represents a period of time during which certain callable loan actions are prohibited.
/// @param Prefunding Starts when a loan is created and ends at fundableAt.
/// In Prefunding, all actions are prohibited or ineffectual.
/// @param Funding Starts at the fundableAt timestamp and ends at the first borrower drawdown.
/// In Funding, lenders can deposit principal to mint a pool token and they can withdraw their deposited principal.
/// @param DrawdownPeriod Starts when the first borrower drawdown occurs and
/// ends after ConfigHelper.DrawdownPeriodInSeconds elapses.
/// In DrawdownPeriod, the borrower can drawdown principal as many times as they want.
/// Lenders cannot withdraw their principal, deposit new principal, or submit call requests.
/// @param InProgress Starts after ConfigHelper.DrawdownPeriodInSeconds elapses and never ends.
/// In InProgress, all post-funding & drawdown actions are allowed (not withdraw, deposit, or drawdown).
/// When a loan is fully paid back, we do not update the loan state, but most of these actions will
/// be prohibited or ineffectual.
enum LoanPhase {
  Prefunding,
  Funding,
  DrawdownPeriod,
  InProgress
}

/// @dev A CallableLoan is a loan which allows the lender to call the borrower's principal.
///     The lender can call the borrower's principal at any time, and the borrower must pay back the principal
///     by the end of the call request period.
/// @dev The ICallableLoanErrors interface contains all errors due to Solidity version compatibility with custom errors.
interface ICallableLoan is ILoan {
  /*================================================================================
  Structs
  ================================================================================*/
  /// @param principalDeposited The amount of principal deposited towards this call request period.
  /// @param principalPaid The amount of principal which has already been paid back towards this call request period.
  ///                      There are 3 ways principal paid can enter a CallRequestPeriod.
  ///                      1. Converted from principalReserved after a call request period becomes due.
  ///                      2. Moved from uncalled tranche as the result of a call request.
  ///                      3. Paid directly when a CallRequestPeriod is past due and has a remaining balance.
  /// @param principalReserved The amount of principal reserved for this call request period.
  ///                          Payments to a not-yet-due CallRequestPeriod are applied to principalReserved.
  /// @param interestPaid The amount of interest paid towards this call request period.
  struct CallRequestPeriod {
    uint256 principalDeposited;
    uint256 principalPaid;
    uint256 principalReserved;
    uint256 interestPaid;
  }

  /// @param principalDeposited The amount of uncalled, deposited principal.
  /// @param principalPaid The amount of principal which has already been paid back.
  ///                      There are two ways uncalled principal can be paid.
  ///                      1. Remainder after drawdowns.
  ///                      2. Conversion from principalReserved after a call request period becomes due.
  ///                         All call requested principal outstanding must already be paid
  ///                         (or have principal reserved) before uncalled principal can be paid.
  ///                      3. Paid directly after term end time.
  /// @param principalReserved The amount of principal reserved for uncalled tranche.
  ///                          principalReserved is greedily moved to call request periods (as much as can fill)
  ///                          when a call request is submitted.
  /// @param interestPaid The amount of interest paid towards uncalled capital.
  struct UncalledCapitalInfo {
    uint256 principalDeposited;
    uint256 principalPaid;
    uint256 principalReserved;
    uint256 interestPaid;
  }

  /*================================================================================
  Functions
  ================================================================================*/
  /// @notice Initialize the pool. Can only be called once, and should be called in the same transaction as
  ///   contract creation to avoid initialization front-running
  /// @param _config address of GoldfinchConfig
  /// @param _borrower address of borrower, a non-transferrable role for performing privileged actions like
  ///   drawdown
  /// @param _numLockupPeriods the number of periods at the tail end of a principal period during which call requests
  ///   are not allowed
  /// @param _interestApr interest rate for the loan
  /// @param _lateFeeApr late fee interest rate for the loan, which kicks in `LatenessGracePeriodInDays` days after a
  ///   payment becomes late
  /// @param _fundableAt earliest time at which the first slice can be funded
  function initialize(
    IGoldfinchConfig _config,
    address _borrower,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _numLockupPeriods,
    ISchedule _schedule,
    uint256 _lateFeeApr,
    uint256 _fundableAt,
    uint256[] calldata _allowedUIDTypes
  ) external;

  /// @notice Submits a call request for the specified pool token and amount
  ///         Mints a new, called pool token of the called amount.
  ///         Splits off any uncalled amount as a new uncalled pool token.
  /// @param amountToCall The amount of the pool token that should be called.
  /// @param poolTokenId The id of the pool token that should be called.
  /// @return callRequestedTokenId  Token id of the call requested token.
  /// @return remainingTokenId Token id of the remaining token.
  function submitCall(
    uint256 amountToCall,
    uint256 poolTokenId
  ) external returns (uint256, uint256);

  function schedule() external view returns (ISchedule);

  function nextDueTimeAt(uint256 timestamp) external view returns (uint256);

  function nextPrincipalDueTime() external view returns (uint256);

  function numLockupPeriods() external view returns (uint256);

  function inLockupPeriod() external view returns (bool);

  function getUncalledCapitalInfo() external view returns (UncalledCapitalInfo memory);

  function getCallRequestPeriod(
    uint256 callRequestPeriodIndex
  ) external view returns (CallRequestPeriod memory);

  function uncalledCapitalTrancheIndex() external view returns (uint256);

  function availableToCall(uint256 tokenId) external view returns (uint256);

  /// @notice Returns the current phase of the loan.
  ///         See documentation on LoanPhase enum.
  function loanPhase() external view returns (LoanPhase);

  /// @notice Returns the current balance of the loan which will be used for
  ///         interest calculations.
  ///         Settles any principal reserved if a call request period has
  ///         ended since the last checkpoint
  ///         Excludes principal reserved for future call request periods
  function interestBearingBalance() external view returns (uint256);

  /// @notice Returns a naive estimate of the interest owed at the timestamp.
  ///         Omits any late fees, and assumes no future payments.
  function estimateOwedInterestAt(uint256 timestamp) external view returns (uint256);

  /// @notice Returns a naive estimate of the interest owed at the timestamp.
  ///         Omits any late fees, and assumes no future payments.
  function estimateOwedInterestAt(
    uint256 balance,
    uint256 timestamp
  ) external view returns (uint256);

  /*================================================================================
  Events
  ================================================================================*/
  event CallRequestSubmitted(
    uint256 indexed originalTokenId,
    uint256 indexed callRequestedTokenId,
    uint256 indexed remainingTokenId,
    uint256 callAmount
  );
  event DepositsLocked(address indexed loan);
}