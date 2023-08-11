// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import { NFTFILoanData as LoanData } from '../../adaptors/lending/NFTFILoanData.sol';

/**
 * @notice An interface to the Nftfi DirectLoanFixedOffer contract.
 * @dev https://github.com/NFTfi-Genesis/nftfi.eth/blob/main/V2/contracts/loans/direct/loanTypes/DirectLoanFixedOffer.sol
 */
interface IDirectLoanFixedOffer {
    /**
     * @notice This event is fired whenever a borrower begins a loan by calling NFTfi.beginLoan(), which can only occur
     * after both the lender and borrower have approved their ERC721 and ERC20 contracts to use NFTfi, and when they
     * both have signed off-chain messages that agree on the terms of the loan.
     *
     * @param  loanId - A unique identifier for this particular loan, sourced from the Loan Coordinator.
     * @param  borrower - The address of the borrower.
     * @param  lender - The address of the lender. The lender can change their address by transferring the NFTfi ERC721
     * token that they received when the loan began.
     */
    event LoanStarted(
        uint32 indexed loanId,
        address indexed borrower,
        address indexed lender,
        LoanData.LoanTerms loanTerms,
        LoanData.LoanExtras loanExtras
    );

    /**
     * @notice This function is called by the borrower when accepting a lender's offer to begin a loan.
     *
     * @param _offer - The offer made by the lender.
     * @param _signature - The components of the lender's signature.
     * @param _borrowerSettings - Some extra parameters that the borrower needs to set when accepting an offer.
     */
    function acceptOffer(
        LoanData.Offer memory _offer,
        LoanData.Signature memory _signature,
        LoanData.BorrowerSettings memory _borrowerSettings
    ) external;

    /**
     * @notice A mapping from a loan's identifier to the loan's details, represented by the loan struct.
     */
    function loanIdToLoan(
        uint32 _loanId
    ) external view returns (LoanData.LoanTerms memory loanTerms);

    /**
     * @notice This function can be called by anyone to repay a loan. It can be called at any time after the loan has
     * begun and before loan expiry. The caller will pay the complete repayment amount. The borrower (current owner of
     * the obligation note) will get the collateral NFT back.
     *
     * @param _loanId  A unique identifier for this particular loan, can be sourced from the Loan Coordinator.
     */
    function payBackLoan(uint32 _loanId) external;
}