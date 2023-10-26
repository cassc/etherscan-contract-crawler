// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./LoanLibrary.sol";

interface IOriginationController {
    function initializeLoanWithItems(
        LoanLibrary.LoanTerms calldata loanTerms,
        address borrower,
        address lender,
        LoanLibrary.Signature calldata sig,
        uint160 nonce,
        LoanLibrary.Predicate[] calldata itemPredicates
    ) external returns (uint256 loanId);
}