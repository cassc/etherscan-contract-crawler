// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IRepaymentAdapter {
    struct BatchRepayment {
        address loanContract;
        address currency;
        uint256 amount;
        bytes data;
    }

    error InvalidCurrencyAddress();

    error InvalidLoanContractAddress();

    error InSufficientBalance();

    error InvalidParameters();

    error InvalidAllowance();

    error InvalidContractCall(string);
}