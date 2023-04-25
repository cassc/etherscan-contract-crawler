//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import "../SkilletProtocolBase.sol";
import "./NftfiAddressProvider.sol";
import "./NftfiLoanOriginator.sol";
import "./NftfiObligationReceipt.sol";
import "./NftfiLoanCoordinator.sol";

import "./interfaces/ILoanCoordinator.sol";
import "./interfaces/ILoanOriginator.sol";
import "./interfaces/IObligationReceipt.sol";

import "./structs/NftfiStructs.sol";

/**
 * Skillet <> Nftfi
 * https://etherscan.io/address/0xE52Cec0E90115AbeB3304BaA36bc2655731f7934#code
 */
contract SkilletxNftfi is 
  SkilletProtocolBase,
  NftfiAddressProvider,
  NftfiLoanOriginator,
  NftfiObligationReceipt,
  NftfiLoanCoordinator
{

  constructor(address _skilletRegistryAddress) SkilletProtocolBase(_skilletRegistryAddress) {}

  event NftfiLoanStarted(
    address indexed borrower, 
    uint256 indexed loanId, 
    uint256 indexed obligationId,
    address collectionAddress,
    uint256 tokenId,
    uint256 netAmountOwed
  );

  event NftfiLoanClosed(
    address indexed borrower, 
    uint256 indexed loanId, 
    uint256 indexed obligationId,
    address collectionAddress,
    uint256 tokenId,
    uint256 netAmountDue
  );

  /**
   * Start a new NFTFi Loan
   * @param loan a structured NFTFi loan object
   * @param borrowerAddress address of the borrower account
   * @param collectionAddress address of the ERC721
   * @param tokenId identifier of the ERC721
   */
  function startNftfiLoan(
    NftfiLoan calldata loan,
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
      loanOriginatorAddress, 
      collectionAddress
    );
    
    // accept loan offer
    acceptOffer(loan);

    // send principal to borrower
    transferERC20(
      address(this),
      borrowerAddress,
      loan.offer.loanERC20Denomination,
      loan.offer.loanPrincipalAmount
    );

    // get loan id
    uint32 loanId = getNewLoanId();

    // mint obligation receipt
    mintObligationReceipt(loanId);

    uint256 obligationId = uint64(uint256(keccak256(abi.encodePacked(loanCoordinatorAddress, loanId))));

    // transfer obligation receipt to borrower
    transferERC721(
      address(this),
      borrowerAddress,
      obligationReceiptAddress,
      obligationId
    );

    emit NftfiLoanStarted(
      borrowerAddress, 
      uint256(loanId), 
      obligationId,
      collectionAddress,
      tokenId,
      loan.offer.loanPrincipalAmount
    );
  }

  /**
   * Close an existing NFTFi Loan
   * @param loanId identifier of the outstanding loan
   * @param borrowerAddress address of the borrower account
   * @param collectionAddress address of the ERC721
   * @param tokenId identifier of the ERC721
   */
  function closeNftfiLoan(
    uint32 loanId,
    address borrowerAddress,
    address collectionAddress,
    uint256 tokenId
  ) public
  {

    // get obligation id from loan id
    uint256 obligationId = uint64(uint256(keccak256(abi.encodePacked(loanCoordinatorAddress, loanId))));

    // transfer obligation to contract
    conduitTransferERC721(
      obligationReceiptAddress,
      borrowerAddress,
      address(this),
      obligationId
    );

    // get loan information from loanId;
    (address currencyAddress, uint256 repaymentAmount) = getLoanRepayment(loanId);

    // transfer repayment from borrower to contract
    conduitTransferERC20(
      currencyAddress,
      borrowerAddress,
      address(this),
      repaymentAmount
    );

    // approve repayment controller for payment transfer
    checkAndSetOperatorApprovalForERC20(
      loanOriginatorAddress, 
      currencyAddress
    );

    // repay loan
    payBackLoan(loanId);

    // transfer ERC721 back to borrower
    transferERC721(
      address(this),
      borrowerAddress,
      collectionAddress,
      tokenId
    );

    emit NftfiLoanClosed(
      borrowerAddress, 
      loanId, 
      obligationId, 
      collectionAddress, 
      tokenId, 
      repaymentAmount
    );
  }
}