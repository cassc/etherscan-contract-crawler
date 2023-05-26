// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IDepositHandler.sol";

interface IPaymentModule is IDepositHandler {
    struct PaymentHolder {
        address tokenAddress;
        uint256 amount;
        uint256 payment;
    }

    struct ProcessPaymentParams {
        address vault;
        address user;
        address referrer;
        FungibleTokenDeposit[] fungibleTokenDeposits;
        NonFungibleTokenDeposit[] nonFungibleTokenDeposits;
        MultiTokenDeposit[] multiTokenDeposits;
        bool isVesting;
    }

    function processPayment(ProcessPaymentParams memory params) external payable;
}