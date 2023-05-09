// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IRepaymentAdapter {
    struct Repayment {
        address loanContract;
        address collection;
        address currency;
        uint256 tokenId;
        uint256 amount;
        uint32 loanId;
    }

    error InvalidCurrencyAddress();

    error InvalidLoanContractAddress();

    error InSufficientBalance();

    error InvalidParameters();

    error InvalidAllowance();

    error InvalidContractCall(string);
}