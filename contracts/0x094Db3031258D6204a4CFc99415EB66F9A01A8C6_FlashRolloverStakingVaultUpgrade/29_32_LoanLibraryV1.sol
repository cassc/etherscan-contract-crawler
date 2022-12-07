// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "../libraries/LoanLibrary.sol";

library LoanLibraryV1 {
    /**
     * @dev The raw terms of a loan
     */
    struct LoanTerms {
        // The number of seconds representing relative due date of the loan
        uint256 durationSecs;
        // The amount of principal in terms of the payableCurrency
        uint256 principal;
        // The amount of interest in terms of the payableCurrency
        uint256 interest;
        // The tokenID of the collateral bundle
        uint256 collateralTokenId;
        // The payable currency for the loan principal and interest
        address payableCurrency;
    }

    /**
     * @dev The data of a loan. This is stored once the loan is Active
     */
    struct LoanData {
        // The tokenId of the borrower note
        uint256 borrowerNoteId;
        // The tokenId of the lender note
        uint256 lenderNoteId;
        // The raw terms of the loan
        LoanTerms terms;
        // The current state of the loan
        LoanLibrary.LoanState state;
        // Timestamp representing absolute due date date of the loan
        uint256 dueDate;
    }
}