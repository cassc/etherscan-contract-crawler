//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import "../../SkilletRegistry.sol";
import "../SkilletProtocolBase.sol";
import "./ArcadeAddressProvider.sol";
import "./ArcadeLoanCore.sol";
import "./ArcadeOriginationController.sol";
import "./ArcadeVaultInteractions.sol";
import "./ArcadeFeeController.sol";

import "./interfaces/IRepaymentController.sol";
import "./interfaces/IFeeController.sol";

import "./structs/ArcadeStructs.sol";

/**
 * Skillet <> Arcade
 * https://docs.arcade.xyz/docs/source-code
 */
contract SkilletxArcade is 
  ArcadeAddressProvider,
  SkilletProtocolBase,
  ArcadeLoanCore,
  ArcadeOriginationController,
  ArcadeVaultInteractions,
  ArcadeFeeController
{
  constructor(address _skilletRegistryAddress) ArcadeVaultInteractions(_skilletRegistryAddress) {}

  event ArcadeLoanStarted(
    address indexed borrower, 
    uint256 indexed vaultId, 
    uint256 indexed loanId,
    address collectionAddress,
    uint256 tokenId,
    uint256 netAmountOwed
  );

  event ArcadeLoanClosed(
    address indexed borrower, 
    uint256 indexed vaultId, 
    uint256 indexed loanId,
    address collectionAddress,
    uint256 tokenId,
    uint256 netAmountDue
  );

  event ArcadeLoanRolledOver(
    address indexed borrower, 
    uint256 indexed oldLoanId, 
    uint256 indexed newLoanId
  );

  /**
   * Start a new Arcade Loan
   * @param loan a structured Arcade loan object
   * @param borrowerAddress address of the borrower account
   * @param collectionAddress address of the ERC721
   * @param tokenId identifier of the ERC721
   */
  function startArcadeLoan(
    ArcadeLoan calldata loan,
    address borrowerAddress,
    address collectionAddress,
    uint256 tokenId
  ) public
  {

    // transfer NFT to contract
    conduitTransferERC721(
      collectionAddress,
      borrowerAddress,
      address(this),
      tokenId
    );

    // initialize an arcade vault
    uint256 vaultId = createVault();
    address vaultAddress = getVaultAddress(vaultId);

    // deposit asset into vault
    depositAsset(vaultAddress, collectionAddress, tokenId);

    // give originator contract access to vault
    approveVaultTransfer(vaultAddress);

    // start new loan with vault
    uint256 loanId = initializeLoan(loan, vaultId);

    // transfer borrowerNote to borrowerAddress
    transferERC721(
      address(this),
      borrowerAddress, 
      getBorrowerNoteAddress(),
      loanId
    );

    // calculate amount owed net of fee
    uint256 netAmountOwed = loan.loanTerms.principal - calculateOriginationFee(loan.loanTerms.principal);

    // transfer principal to borrowerAddress
    transferERC20(
      address(this),
      borrowerAddress,
      loan.loanTerms.payableCurrency, 
      netAmountOwed
    );

    emit ArcadeLoanStarted(
      borrowerAddress, 
      vaultId, 
      loanId,
      collectionAddress,
      tokenId,
      netAmountOwed
    );
  }

  /**
   * Close an existing Arcade Loan
   * @param loanId identifier of the outstanding loan
   * @param borrowerAddress address of the borrower account
   * @param collectionAddress address of the ERC721
   * @param tokenId identifier of the ERC721
   */
  function closeArcadeLoan(
    uint256 loanId,
    address borrowerAddress,
    address collectionAddress,
    uint256 tokenId
  ) public
  {

    conduitTransferERC721(
      getBorrowerNoteAddress(),
      borrowerAddress,
      address(this),
      loanId
    );

    // get the loan information
    (uint256 vaultId, uint256 principal, uint256 interestRate, address payableCurrency) = getLoanData(loanId);

    // get the full repayment amount
    uint256 repayment = getTotalRepaymentAmount(principal, interestRate);

    conduitTransferERC20(
      payableCurrency,
      borrowerAddress,
      address(this),
      repayment
    );

    // approve repayment controller for payment transfer
    checkAndSetOperatorApprovalForERC20(
      repaymentControllerAddress, 
      payableCurrency
    );

    // payback the loan
    IRepaymentController repaymentController = IRepaymentController(repaymentControllerAddress);
    repaymentController.repay(loanId);

    // withdraw the asset from the vault
    ArcadeVaultInteractions.withdrawAsset(
      vaultId,
      borrowerAddress,
      collectionAddress,
      tokenId
    );

    emit ArcadeLoanClosed(
      borrowerAddress, 
      vaultId, 
      loanId,
      collectionAddress,
      tokenId,
      repayment
    );
  }

  /**
   * Rollover an existing Arcade Loan to a new loan
   * @param loan a well structured Arcade loan object
   * @param oldLoanId identifier of the outstanding loan
   * @param borrowerAddress address of the borrower account
   */
  function rolloverArcadeLoan(
    ArcadeLoan calldata loan,
    uint256 oldLoanId,
    address borrowerAddress
  ) public 
  {

    conduitTransferERC721(
      getBorrowerNoteAddress(),
      borrowerAddress,
      address(this),
      oldLoanId
    );

    // get the loan information
    (uint256 vaultId, uint256 principal, uint256 interestRate,) = getLoanData(oldLoanId);

    // get net amount owed to borrower from rollover
    uint256 oldLoanRepayment = getTotalRepaymentAmount(principal, interestRate);

    uint256 totalFee = calculateRolloverFee(loan.loanTerms.principal);
    
    if (loan.loanTerms.principal < oldLoanRepayment + totalFee) {
      uint256 paymentDue = oldLoanRepayment + totalFee - loan.loanTerms.principal;
      conduitTransferERC20(
        loan.loanTerms.payableCurrency,
        borrowerAddress,
        address(this),
        paymentDue
      );

      approveOperatorForERC20(
        originationControllerAddress,
        loan.loanTerms.payableCurrency
      );
    }

    // rollover the loan
    uint256 newLoanId = rolloverLoan(oldLoanId, loan, vaultId);

    // transfer borrowerNote to borrowerAddress
    transferERC721(
      address(this),
      borrowerAddress,
      getBorrowerNoteAddress(), 
      newLoanId
    );
    
    if (loan.loanTerms.principal > oldLoanRepayment + totalFee) {
      uint256 paymentOwed = loan.loanTerms.principal - (oldLoanRepayment + totalFee);
      transferERC20(
        address(this),
        borrowerAddress,
        loan.loanTerms.payableCurrency,
        paymentOwed
      );
    }

    emit ArcadeLoanRolledOver(
      borrowerAddress, 
      oldLoanId, 
      newLoanId
    );
  }
}