// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "MultiToken/MultiToken.sol";


library PWNLOANTerms {

    /**
     * @notice Struct defining a simple loan terms.
     * @dev This struct is created by loan factories and never stored.
     * @param lender Address of a lender.
     * @param borrower Address of a borrower.
     * @param expiration Unix timestamp (in seconds) setting up a default date.
     * @param collateral Asset used as a loan collateral. For a definition see { MultiToken dependency lib }.
     * @param asset Asset used as a loan credit. For a definition see { MultiToken dependency lib }.
     * @param loanRepayAmount Amount of a loan asset to be paid back.
     */
    struct Simple {
        address lender;
        address borrower;
        uint40 expiration;
        MultiToken.Asset collateral;
        MultiToken.Asset asset;
        uint256 loanRepayAmount;
    }

}