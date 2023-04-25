// SPDX-License-Identifier: Skillet Group
pragma solidity ^0.8.0;

import "./interfaces/ILoanOriginator.sol";

import "./NftfiAddressProvider.sol";

import "./structs/NftfiStructs.sol";

contract NftfiLoanOriginator is NftfiAddressProvider {

  function getLoanRepayment(
    uint32 loanId
  ) public
    view
    returns (
      address currencyAddress,
      uint256 repaymentAmount
    )
  {
    ILoanOriginator originator = ILoanOriginator(loanOriginatorAddress);
    ILoanOriginator.LoanTerms memory loanTerms = originator.loanIdToLoan(loanId);
    currencyAddress = loanTerms.loanERC20Denomination;
    repaymentAmount = loanTerms.maximumRepaymentAmount; 
  }

  function mintObligationReceipt(
    uint32 loanId
  ) internal
  {
    ILoanOriginator originator = ILoanOriginator(loanOriginatorAddress);
    originator.mintObligationReceipt(loanId);
  }

  function acceptOffer(
    NftfiLoan calldata loan
  ) internal
  {
    ILoanOriginator originator = ILoanOriginator(loanOriginatorAddress);
    originator.acceptOffer(
      loan.offer,
      loan.sig,
      loan.borrowerSettings
    );
  }

  function payBackLoan(
    uint32 loanId
  ) internal
  {
    ILoanOriginator originator = ILoanOriginator(loanOriginatorAddress);
    originator.payBackLoan(loanId);
  }
}