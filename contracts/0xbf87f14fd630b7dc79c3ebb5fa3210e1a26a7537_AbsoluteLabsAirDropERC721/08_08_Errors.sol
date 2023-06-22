// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

library Errors {
    // AbsoluteLabsAirDrop.sol
    error InsufficientAllowance();
    error InsufficientBalanceToWithdraw();
    error InsufficientBalanceToFund();
    error InsufficientBalance();
    error NotTheTokenOwner();
    error RecipientsAndIDsAreNotTheSameLength();
    error ArrayLengthDoesntMatch();
    error CallHasFailed();
}