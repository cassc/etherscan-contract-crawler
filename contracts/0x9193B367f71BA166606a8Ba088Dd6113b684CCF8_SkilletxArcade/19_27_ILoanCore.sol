//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

/**
 * Skillet <> Arcade
 * Loan Core Interface
 * https://etherscan.io/address/0x81b2F8Fc75Bab64A6b144aa6d2fAa127B4Fa7fD9#code
 */
interface ILoanCore {
  enum LoanState {
    DUMMY_DO_NOT_USE,
    Active,
    Repaid,
    Defaulted
  }

  struct LoanTerms {
    uint32 durationSecs;
    uint32 deadline;
    uint24 numInstallments;
    uint160 interestRate;
    uint256 principal;
    address collateralAddress;
    uint256 collateralId;
    address payableCurrency;
  }

  struct LoanData {
    LoanState state;
    uint24 numInstallmentsPaid;
    uint160 startDate;
    LoanTerms terms;
    uint256 balance;
    uint256 balancePaid;
    uint256 lateFeesAccrued;
  }

  function getLoan(uint256 loanId) external view returns (LoanData memory);
  function getFullInterestAmount(uint256 principal, uint256 interestRate) external pure returns (uint256);
  function feeController() external view returns (address);
  function borrowerNote() external view returns (address);
}