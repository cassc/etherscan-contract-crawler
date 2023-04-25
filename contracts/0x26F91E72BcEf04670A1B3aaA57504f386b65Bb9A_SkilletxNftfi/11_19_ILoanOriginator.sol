// SPDX-License-Identifier: Skillet Group
pragma solidity ^0.8.0;

/**
 * Skillet <> NFTfi
 * NFTFi Loan Originator
 * https://etherscan.io/address/0xE52Cec0E90115AbeB3304BaA36bc2655731f7934#code
 */
interface ILoanOriginator {

  struct LoanTerms {
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 nftCollateralId;
    address loanERC20Denomination;
    uint32 loanDuration;
    uint16 loanInterestRateForDurationInBasisPoints;
    uint16 loanAdminFeeInBasisPoints;
    address nftCollateralWrapper;
    uint64 loanStartTime;
    address nftCollateralContract;
    address borrower;
  }

  struct Offer {
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 nftCollateralId;
    address nftCollateralContract;
    uint32 loanDuration;
    uint16 loanAdminFeeInBasisPoints;
    address loanERC20Denomination;
    address referrer;
  }

  struct Signature {
    uint256 nonce;
    uint256 expiry;
    address signer;
    bytes signature;
  }

  struct BorrowerSettings {
    address revenueSharePartner;
    uint16 referralFeeInBasisPoints;
  }

  function loanIdToLoan(uint32 loanId) external view returns (LoanTerms memory);
  function acceptOffer(Offer memory _offer, Signature memory _signature, BorrowerSettings memory _borrowerSettings) external;
  function payBackLoan(uint32 loanId) external;
  function mintObligationReceipt(uint32 _loanId) external;
}