//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import "./interfaces/ILoanCore.sol";
import "./ArcadeAddressProvider.sol";

contract ArcadeLoanCore is ArcadeAddressProvider{
  
  /**
   * Get Loan Data
   * https://etherscan.io/address/0x81b2f8fc75bab64a6b144aa6d2faa127b4fa7fd9#readProxyContract#F14
   * @param loanId the identifier of the outstanding loan
   */
  function getLoanData(
    uint256 loanId
  ) public
    view
    returns (
      uint256 vaultId,
      uint256 principal,
      uint256 interestRate,
      address payableCurrency
    )
  {
    ILoanCore loanCore = ILoanCore(loanCoreAddress);
    ILoanCore.LoanData memory data = loanCore.getLoan(loanId);

    // get the loan terms associated with the loan
    ILoanCore.LoanTerms memory loanTerms = data.terms;
    vaultId = loanTerms.collateralId;
    principal = loanTerms.principal;
    interestRate = loanTerms.interestRate;
    payableCurrency = loanTerms.payableCurrency;
  }

  function getTotalRepaymentAmount(
    uint256 principal,
    uint256 interestRate
  ) public
    view
    returns (uint256 repaymentAmount)
  {
    ILoanCore loanCore = ILoanCore(loanCoreAddress);
    repaymentAmount = loanCore.getFullInterestAmount(principal, interestRate);
  }

  /**
   * Get Borrower Address
   * https://etherscan.io/address/0x81b2f8fc75bab64a6b144aa6d2faa127b4fa7fd9#readProxyContract#F10
   * @return borrowerNoteAddress address of the borrowerNote implementation
   */
  function getBorrowerNoteAddress() public view returns (address borrowerNoteAddress)
  {
    ILoanCore loanCore = ILoanCore(loanCoreAddress);
    borrowerNoteAddress = loanCore.borrowerNote();
  }
}