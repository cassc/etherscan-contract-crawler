//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import "../SkilletProtocolBase.sol";
import "./X2Y2AddressProvider.sol";
import "./X2Y2ServiceFee.sol";
import "./X2Y2Originator.sol";
import "./X2Y2Utils.sol";

import "./interfaces/IXY3.sol";

import "./structs/X2Y2Structs.sol";

/**
 * Skillet <> X2Y2
 * https://etherscan.io/address/0xfa4d5258804d7723eb6a934c11b1bd423bc31623#code
 */
contract SkilletxX2Y2 is 
  SkilletProtocolBase,
  X2Y2AddressProvider,
  X2Y2ServiceFee,
  X2Y2Originator,
  X2Y2Utils
{

  constructor(address _skilletRegistryAddress) SkilletProtocolBase(_skilletRegistryAddress) {}

  event X2Y2LoanStarted(
    address indexed borrower, 
    uint256 indexed loanId, 
    uint256 indexed obligationId,
    address collectionAddress,
    uint256 tokenId,
    uint256 netAmountOwed
  );

  event X2Y2LoanClosed(
    address indexed borrower, 
    uint256 indexed loanId, 
    uint256 indexed obligationId,
    address collectionAddress,
    uint256 tokenId,
    uint256 netAmountDue
  );

  event X2Y2LoanRolledOver(
    address indexed borrower, 
    uint256 indexed oldLoanId, 
    uint256 indexed newLoanId
  );

  /**
   * Start a new X2Y2 Loan
   * @param loan a structured X2Y2 loan object
   * @param borrowerAddress address of the borrower account
   * @param collectionAddress address of the ERC721
   * @param tokenId identifier of the ERC721
   */
  function startX2Y2Loan(
    X2Y2Loan calldata loan,
    address borrowerAddress,
    address collectionAddress,
    uint256 tokenId
  ) public 
  {

    // transfer ERC721 to contract
    conduitTransferERC721(
      collectionAddress,
      borrowerAddress,
      address(this),
      tokenId
    );

    // check and set approval for DirectLoanFixedCollectionOffer
    checkAndSetOperatorApprovalForERC721(
      addressProvider.getTransferDelegate(), 
      collectionAddress
    );
    
    // start loan offer
    uint32 loanId = borrow(loan, tokenId);

    // get borrowerNoteId
    uint256 borrowerNoteId = getBorrowerNoteId(loanId);

    // send principal to borrower
    transferERC20(
      address(this),
      borrowerAddress,
      loan.offer.borrowAsset,
      loan.offer.borrowAmount
    );

    // transfer obligation receipt to borrower
    transferERC721(
      address(this),
      borrowerAddress,
      addressProvider.getBorrowerNote(),
      borrowerNoteId
    );

    emit X2Y2LoanStarted(
      borrowerAddress, 
      uint256(loanId), 
      borrowerNoteId,
      collectionAddress,
      tokenId,
      loan.offer.borrowAmount
    );
  }

  /**
   * Repay an existing X2Y2 Loan
   * @param loanId identifier of the outstanding loan
   * @param borrowerAddress address of the borrower account
   * @param collectionAddress address of the ERC721
   * @param tokenId identifier of the ERC721
   */
  function repayX2Y2Loan(
    uint32 loanId,
    address borrowerAddress,
    address collectionAddress,
    uint256 tokenId
  ) public
  {

    // get borrowerNote id from loanId
    uint256 borrowerNoteId = getBorrowerNoteId(loanId);

    // transfer borrowerNote to contract
    conduitTransferERC721(
      addressProvider.getBorrowerNote(),
      borrowerAddress,
      address(this),
      borrowerNoteId
    );

    // get loan information
    IXY3.LoanDetail memory _loanDetails = getLoanDetails(loanId);

    // transfer currency to contract
    conduitTransferERC20(
      _loanDetails.borrowAsset,
      borrowerAddress,
      address(this),
      _loanDetails.repayAmount
    );

    // approve x2y2 delegate
    approveOperatorForERC20(
      addressProvider.getTransferDelegate(),
      _loanDetails.borrowAsset
    );

    // repay loan
    repay(loanId);

    // transfer asset back to borrower
    transferERC721(
      address(this),
      borrowerAddress,
      collectionAddress,
      tokenId
    );

    emit X2Y2LoanClosed(
      borrowerAddress, 
      uint256(loanId), 
      borrowerNoteId,
      collectionAddress,
      tokenId,
      _loanDetails.repayAmount
    );
  }

  /**
   * Rollover an X2Y2 loan into a new loan
   * @param loan a structured X2Y2 loan object
   * @param borrowerAddress address of the borrower account
   */
  function rolloverX2Y2Loan(
    X2Y2Loan calldata loan,
    address borrowerAddress
  ) public
  {

    // decode the extraDeal data into the oldLoanId
    uint32 oldLoanId = abi.decode(loan.extraDeal.data, (uint32));

    // get borrowerNoteId from the oldLoanId
    uint256 borrowerNoteId = getBorrowerNoteId(oldLoanId);
    
    // transfer the borrowerNote to the contract
    conduitTransferERC721(
      addressProvider.getBorrowerNote(),
      borrowerAddress,
      address(this),
      borrowerNoteId
    );

    // get loan information
    IXY3.LoanDetail memory _loanDetails = getLoanDetails(oldLoanId);

    // approve x2y2 delegate
    approveOperatorForERC20(
      addressProvider.getTransferDelegate(),
      _loanDetails.borrowAsset
    );

    // calculate total rollover fee
    uint256 totalServiceFee = calculateServiceFee(
      loan.offer.borrowAmount,
      _loanDetails.nftAsset
    );
    
    // transfer amount due for repayment from user to contract
    if (loan.offer.borrowAmount < _loanDetails.repayAmount + totalServiceFee) {
      uint256 paymentDue = _loanDetails.repayAmount + totalServiceFee - loan.offer.borrowAmount;
      conduitTransferERC20(
        _loanDetails.borrowAsset,
        borrowerAddress,
        address(this),
        paymentDue
      );
    }
    
    // start new loan offer
    uint32 newLoanId = borrow(loan, _loanDetails.nftTokenId);

    // get borrowerNoteId
    uint256 newBorrowerNoteId = getBorrowerNoteId(newLoanId);

    // transfer new borrowerNote to borrower
    transferERC721(
      address(this),
      borrowerAddress,
      addressProvider.getBorrowerNote(),
      newBorrowerNoteId
    );

    // transfer amount owed from net principal from contract to the user
    if (loan.offer.borrowAmount > _loanDetails.repayAmount + totalServiceFee) {
      uint256 paymentOwed = loan.offer.borrowAmount - (_loanDetails.repayAmount + totalServiceFee);
      transferERC20(
        address(this),
        borrowerAddress,
        _loanDetails.borrowAsset,
        paymentOwed
      );
    }

    emit X2Y2LoanRolledOver(
      borrowerAddress,
      uint256(oldLoanId),
      uint256(newLoanId)
    );
  }
}