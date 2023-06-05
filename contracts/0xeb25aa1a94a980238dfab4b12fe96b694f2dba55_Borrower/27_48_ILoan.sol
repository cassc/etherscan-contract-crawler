// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;
import {ISchedule} from "./ISchedule.sol";
import {ICreditLine} from "./ICreditLine.sol";

enum LoanType {
  TranchedPool,
  CallableLoan
}

interface ILoan {
  /// @notice getLoanType was added to support the new callable loan type.
  ///         It is not supported in older versions of ILoan (e.g. legacy TranchedPools)
  function getLoanType() external view returns (LoanType);

  /// @notice Pool's credit line, responsible for managing the loan's accounting variables
  function creditLine() external view returns (ICreditLine);

  /// @notice Time when the pool was initialized. Zero if uninitialized
  function createdAt() external view returns (uint256);

  /// @notice Pay down interest + principal. Excess payments are refunded to the caller
  /// @param amount USDC amount to pay
  /// @return PaymentAllocation info on how the payment was allocated
  /// @dev {this} must be approved by msg.sender to transfer {amount} of USDC
  function pay(uint256 amount) external returns (PaymentAllocation memory);

  /// @notice Compute interest and principal owed on the current balance at a future timestamp
  /// @param timestamp time to calculate up to
  /// @return interestOwed amount of obligated interest owed at `timestamp`
  /// @return interestAccrued amount of accrued interest (not yet owed) that can be paid at `timestamp`
  /// @return principalOwed amount of principal owed at `timestamp`
  function getAmountsOwed(
    uint256 timestamp
  ) external view returns (uint256 interestOwed, uint256 interestAccrued, uint256 principalOwed);

  function getAllowedUIDTypes() external view returns (uint256[] memory);

  /// @notice Drawdown the loan. The credit line's balance should increase by the amount drawn down.
  ///   Junior capital must be locked before this function can be called. If senior capital isn't locked
  ///   then this function will lock it for you (convenience to avoid calling lockPool() separately).
  ///   This function should revert if the amount requested exceeds the the current slice's currentLimit
  ///   This function should revert if the caller is not the borrower.
  /// @param amount USDC to drawdown. This amount is transferred to the caller
  function drawdown(uint256 amount) external;

  /// @notice Update `fundableAt` to a new timestamp. Only the borrower can call this.
  function setFundableAt(uint256 newFundableAt) external;

  /// @notice Supply capital to this pool. Caller can't deposit to the junior tranche if the junior pool is locked.
  ///   Caller can't deposit to a senior tranche if the pool is locked. Caller can't deposit if they are missing the
  ///   required UID NFT.
  /// @param tranche id of tranche to supply capital to. Id must correspond to a tranche in the current slice.
  /// @param amount amount of capital to supply
  /// @return tokenId NFT representing your position in this pool
  function deposit(uint256 tranche, uint256 amount) external returns (uint256 tokenId);

  function depositWithPermit(
    uint256 tranche,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 tokenId);

  /// @notice Query the max amount available to withdraw for tokenId's position
  /// @param tokenId position to query max amount withdrawable for
  /// @return interestRedeemable total interest withdrawable on the position
  /// @return principalRedeemable total principal redeemable on the position
  function availableToWithdraw(
    uint256 tokenId
  ) external view returns (uint256 interestRedeemable, uint256 principalRedeemable);

  /// @notice Withdraw an already deposited amount if the funds are available. Caller must be the owner or
  ///   approved by the owner on tokenId. Amount withdrawn is sent to the caller.
  /// @param tokenId the NFT representing the position
  /// @param amount amount to withdraw (must be <= interest+principal available to withdraw)
  /// @return interestWithdrawn interest withdrawn
  /// @return principalWithdrawn principal withdrawn
  function withdraw(
    uint256 tokenId,
    uint256 amount
  ) external returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

  /// @notice Similar to withdraw but withdraw the max interest and principal available for `tokenId`
  function withdrawMax(
    uint256 tokenId
  ) external returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

  /// @notice Withdraw from multiple tokens
  /// @param tokenIds NFT positions to withdraw. Caller must be an owner or approved on all tokens in the array
  /// @param amounts amounts to withdraw from positions such that amounts[i] is withdrawn from position tokenIds[i]
  function withdrawMultiple(uint256[] calldata tokenIds, uint256[] calldata amounts) external;

  /// @notice Result of applying a payment to a v2 pool
  /// @param owedInterestPayment payment portion of interest owed
  /// @param accruedInterestPayment payment portion of accrued (but not yet owed) interest
  /// @param principalPayment payment portion on principal owed
  /// @param additionalBalancePayment payment portion on any balance that is currently owed
  /// @param paymentRemaining payment amount leftover
  struct PaymentAllocation {
    uint256 owedInterestPayment;
    uint256 accruedInterestPayment;
    uint256 principalPayment;
    uint256 additionalBalancePayment;
    uint256 paymentRemaining;
  }
  /// @notice Event emitted on payment
  /// @param payer address that made the payment
  /// @param pool pool to which the payment was made
  /// @param interest amount of payment allocated to interest (obligated + additional)
  /// @param principal amount of payment allocated to principal owed and remaining balance
  /// @param remaining any excess payment amount that wasn't allocated to a debt owed
  /// @param reserve of payment that went to the protocol reserve
  event PaymentApplied(
    address indexed payer,
    address indexed pool,
    uint256 interest,
    uint256 principal,
    uint256 remaining,
    uint256 reserve
  );
  event DepositMade(
    address indexed owner,
    uint256 indexed tranche,
    uint256 indexed tokenId,
    uint256 amount
  );

  /// @notice While owner is the label of the first argument, it is actually the sender of the transaction.
  event WithdrawalMade(
    address indexed owner,
    uint256 indexed tranche,
    uint256 indexed tokenId,
    uint256 interestWithdrawn,
    uint256 principalWithdrawn
  );
  event ReserveFundsCollected(address indexed from, uint256 amount);
  event DrawdownMade(address indexed borrower, uint256 amount);
  event DrawdownsPaused(address indexed pool);
  event DrawdownsUnpaused(address indexed pool);
  event EmergencyShutdown(address indexed pool);
}