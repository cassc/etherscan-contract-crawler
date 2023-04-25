// SPDX-License-Identifier: Skillet Group
pragma solidity ^0.8.0;

import "./interfaces/IObligationReceipt.sol";

import "./NftfiAddressProvider.sol";

contract NftfiObligationReceipt is NftfiAddressProvider {

  function getLoanId(
    uint256 obligationId
  ) public 
    view
    returns (uint256 loanId)
  {
    IObligationReceipt obligationReceipt = IObligationReceipt(obligationReceiptAddress);
    IObligationReceipt.Loan memory loan = obligationReceipt.loans(obligationId);
    loanId = loan.loanId;
  }

  function getObligationId(
    uint32 loanId
  ) public
    view
    returns (uint256 obligationId)
  {
    obligationId = uint64(uint256(keccak256(abi.encodePacked(loanCoordinatorAddress, loanId))));
  }
}