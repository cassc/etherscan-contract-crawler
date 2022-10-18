// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IDepositHandler.sol";

interface IPaymentModule is IDepositHandler {
    struct PaymentHolder {
        address tokenAddress;
        uint256 amount;
        uint256 payment;
    }

    function processPayment(
        address vault,
        address user,
        address referrer,
        FungibleTokenDeposit[] memory fungibleTokenDeposits,
        NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        MultiTokenDeposit[] memory multiTokenDeposit,
        bool isVesting
    ) external;
}