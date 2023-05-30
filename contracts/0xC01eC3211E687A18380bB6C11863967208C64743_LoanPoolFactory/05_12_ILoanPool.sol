// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ICreditLineBase.sol";

interface ILoanPool {
  /// @notice Amount is zero
  error ZeroAmount();

  /// @notice Funding period has not started
  error FundingPeriodNotStarted();

  /// @notice Funding period has ended
  error FundingPeriodEnded();

  /// @notice Funding period has not ended
  error FundingPeriodNotEnded();

  /// @notice Minimum amount of funds has been raised
  error MinimumFundingReached();

  /// @notice Minimum amount of funds has not been raised
  error MinimumFundingNotReached();

  /// @notice Drawdown period has not ended
  error DrawdownPeriodNotEnded();

  /// @notice Drawdown period has ended
  error DrawdownPeriodEnded();

  /// @notice Loan is not in funding state
  error NotFundingState();

  /// @notice Loan is not in repayment or repaid state
  error NotRepaymentOrRepaidState();

  /// @notice Insufficient balance for withdraw
  error InsufficientBalance();

  /// @notice Tokens cannot be transferred
  error TransferDisabled();

  /// @notice Attempt to transfer token which has claimed repayments
  error EncumberedTokenTransfer();

  /// @notice Attempt to unwithdraw more than what was withdrawn
  error ExcessiveUnwithdraw();

  /// @notice Loan is not in refund state
  error NotRefundState();

  /// @notice Caller is not the borrower
  error NotBorrower();

  /// @notice Funds have been deposited into the loan pool
  /// @param lender Address of the lender
  /// @param recipient Address where loan token is credited to
  /// @param amount Amount of funds deposited
  event Fund(address indexed lender, address indexed recipient, uint256 amount);

  /// @notice Lenders are allowed to withdraw their funds from the loan pool
  event Refunded();

  /// @notice Borrower has drawndown on the loan
  event Drawndown(address indexed borrower, uint256 amount);

  /// @notice Fees are collected from the loan pool
  /// @param borrower Address of borrower
  /// @param recipient Address where fees are credited to
  /// @param amount Amount of fees collected
  event FeesCollected(
    address indexed borrower,
    address indexed recipient,
    uint256 amount
  );

  /// @notice Funds are beind refunded to lender
  /// @param lender Address of the lender
  /// @param recipient Address where refunds are being sent
  /// @param amount Amount of funds refunded
  event Refund(
    address indexed lender,
    address indexed recipient,
    uint256 amount
  );

  /// @notice Borrower repays funds to the loan pool
  /// @param payer Address of the payer
  /// @param amount Amount of funds repaid
  event Repay(address indexed payer, uint256 amount);

  /// @notice Additional payments was refunded to the borrower
  /// @param payer Address of the payer
  /// @param amount Amount of funds refunded
  event RefundAdditionalPayment(address indexed payer, uint256 amount);

  /// @notice Funds are being withdrawn from the loan pool as lender
  /// after funds are repaid by the borrower
  /// @param lender Address of the lender
  /// @param recipient Address where funds are being sent
  /// @param amount Amount of funds withdrawn
  event Withdraw(
    address indexed lender,
    address indexed recipient,
    uint256 amount
  );

  /// @notice Funds are being returned to the loan pool by lender
  /// usually to free up more tokens for transfer
  /// @param sender Address of the sender
  /// @param lender Address where refunds are processed
  /// @param amount Amount of funds withdrawn
  event Unwithdraw(
    address indexed sender,
    address indexed lender,
    uint256 amount
  );

  function initialize(
    ICreditLineBase _creditLine,
    IERC20 _fundingAsset,
    address _borrower,
    address _feeRecipient,
    uint256[12] calldata _uints // collapsing because of stack too deep
  ) external;

  function creditLine() external view returns (ICreditLineBase);

  function fundingAsset() external view returns (IERC20);

  function borrower() external view returns (address);

  function deployer() external view returns (address);

  function feeRecipient() external view returns (address);

  function fundingStart() external view returns (uint256);

  function fundingEnd() external view returns (uint256);

  function minFundingRequired() external view returns (uint256);

  function drawdownPeriod() external view returns (uint256);

  function fees() external view returns (uint256);

  function repayments(address) external view returns (uint256);

  function fund(uint256 amount, address recipient) external;

  function fundDangerous(address recipient) external;

  function refundMinimumNotMet() external;

  function refundInactiveBorrower() external;

  function refund(address recipient) external;

  function drawdown() external;

  function repay(uint256 amount) external;

  function withdraw(uint256 amount, address recipient) external;

  function unwithdraw(uint256 amount, address recipient) external;

  function maxRepaymentAmount(
    address account
  ) external view returns (uint256 repaymentCeiling);

  function balanceAvailable(
    address account
  ) external view returns (uint256 balance);

  function shareOfPool(address account) external view returns (uint256 share);
}