//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import "./interfaces/IXY3.sol";
import "./X2Y2AddressProvider.sol";

import "./structs/X2Y2Structs.sol";

/**
 * Skillet <> X2Y2
 */
contract X2Y2Originator is X2Y2AddressProvider {

  function getLoanAddress() public view returns (address loanAddress) {
    loanAddress = addressProvider.getXY3();
  }

  function getLoanDetails(
    uint32 loanId
  ) public 
    view 
    returns (IXY3.LoanDetail memory loanDetails) 
  {
    IXY3 originator = IXY3(addressProvider.getXY3());
    loanDetails = originator.loanDetails(loanId);
  }

  function borrow(
    X2Y2Loan memory loan,
    uint256 tokenId
  ) public
    returns (uint32 loanId)
  {
    IXY3 originator = IXY3(addressProvider.getXY3());
    loanId = originator.borrow(
      loan.offer,
      tokenId,
      loan.isCollectionOffer,
      loan.lenderSignature,
      loan.brokerSignature,
      loan.extraDeal
    );
  }

  function repay(
    uint32 loanId
  ) public
  {
    IXY3 originator = IXY3(addressProvider.getXY3());
    originator.repay(loanId);
  }
}