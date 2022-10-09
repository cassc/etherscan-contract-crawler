// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IPaymentSplitter {
    event PaymentReceived(address from, uint256 amount);
    error PaymentFailed();
}