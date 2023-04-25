//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

/**
 * Skillet <> Arcade
 * Origination Controller Interface
 * https://etherscan.io/address/0x4c52ca29388A8A854095Fd2BeB83191D68DC840b#code
 */
interface IOriginationController {
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

  struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct Predicate {
    bytes data;
    address verifier;
  }

  function initializeLoanWithItems(
    LoanTerms calldata loanTerms,
    address borrower,
    address lender,
    Signature calldata sig,
    uint160 nonce,
    Predicate[] calldata itemPredicates
  ) external returns (uint256);

  function rolloverLoanWithItems(
    uint256 oldLoanId,
    LoanTerms calldata loanTerms,
    address lender,
    Signature calldata sig,
    uint160 nonce,
    Predicate[] calldata itemPredicates
  ) external returns (uint256 newLoanId);
}