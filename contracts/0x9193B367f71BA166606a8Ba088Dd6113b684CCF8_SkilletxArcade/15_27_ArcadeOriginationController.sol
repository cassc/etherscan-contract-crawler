//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import "./ArcadeAddressProvider.sol";
import "./interfaces/IOriginationController.sol";
import "./structs/ArcadeStructs.sol";

contract ArcadeOriginationController is ArcadeAddressProvider {

  /**
   * Intialize a new Arcade loan
   * https://etherscan.io/address/0x4c52ca29388A8A854095Fd2BeB83191D68DC840b#writeProxyContract#F7
   * @param loan a well structured Arcade loan object
   * @param vaultId identifier of the vault containing the asset
   */
  function initializeLoan(
    ArcadeLoan calldata loan,
    uint256 vaultId
  ) internal 
    returns (uint256 loanId)
  {
    // match loan terms and item predicates
    IOriginationController.LoanTerms memory matchingLoanTerms = matchLoanTerms(loan.loanTerms, vaultId);
    IOriginationController.Predicate[] memory predicates = matchItemPredicates(loan.itemPredicate);

    // initialize loan
    IOriginationController originationController = IOriginationController(originationControllerAddress);
    loanId = originationController.initializeLoanWithItems(
      matchingLoanTerms,
      address(this),
      loan.lenderAddress,
      loan.sig,
      loan.nonce,
      predicates
    );
  }

  /**
   * Rollover an Arcade loan into a new loan
   * https://etherscan.io/address/0x4c52ca29388A8A854095Fd2BeB83191D68DC840b#writeProxyContract#F11
   * @param oldLoanId identifier of the outstanding loan
   * @param loan a well structured Arcade loan object
   * @param vaultId identifier of the vault containing the asset
   * @return newLoanId identifier of the new loan
   */
  function rolloverLoan(
    uint256 oldLoanId,
    ArcadeLoan calldata loan,
    uint256 vaultId
  ) internal
    returns (uint256 newLoanId)
  {
    // match loan terms and item predicates
    IOriginationController.LoanTerms memory matchingLoanTerms = matchLoanTerms(loan.loanTerms, vaultId);
    IOriginationController.Predicate[] memory predicates = matchItemPredicates(loan.itemPredicate);

    // rollover loan
    IOriginationController originationController = IOriginationController(originationControllerAddress);
    newLoanId = originationController.rolloverLoanWithItems(
      oldLoanId,
      matchingLoanTerms,
      loan.lenderAddress,
      loan.sig,
      loan.nonce,
      predicates
    );
  }

  /**
   * Match loan terms
   * adds newly created vaultId to the loan terms 
   * @param loanTerms base loan terms without vaultId
   * @param vaultId identifier of the newly created vault
   * @return matchedLoanTerms well structured Arcade loan object
   */
  function matchLoanTerms(
    BaseLoanTerms calldata loanTerms,
    uint256 vaultId
  ) internal
    view
    returns (IOriginationController.LoanTerms memory matchedLoanTerms)
  {
    matchedLoanTerms = IOriginationController.LoanTerms({
      durationSecs: loanTerms.durationSecs,
      deadline: loanTerms.deadline,
      numInstallments: loanTerms.numInstallments,
      interestRate: loanTerms.interestRate,
      principal: loanTerms.principal,
      collateralAddress: vaultFactoryAddress,
      collateralId: vaultId,
      payableCurrency:loanTerms.payableCurrency
    });
  }

  /**
   * Match item predicates
   * formats single predicate into an array of predicates
   * @param predicate the original predicate
   * @return predicates an array of size one of single item predicate
   */
  function matchItemPredicates(
    IOriginationController.Predicate calldata predicate
  ) internal
    pure
    returns (IOriginationController.Predicate[] memory predicates)
  {
    predicates = new IOriginationController.Predicate[](1);
    predicates[0] = IOriginationController.Predicate(
      predicate.data,
      predicate.verifier
    );
  }
}