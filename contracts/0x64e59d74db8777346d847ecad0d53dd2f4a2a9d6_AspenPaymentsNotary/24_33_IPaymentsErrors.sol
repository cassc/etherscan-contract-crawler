// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IPaymentsErrorsV0 {
    error InvalidPaymentAmount();
    error InvalidFeeReceiver();
    error InvalidFeeBps();
    error ZeroPaymentAmount();
}

interface IPaymentsErrorsV1 is IPaymentsErrorsV0 {
    error InvalidGlobalConfigAddress();
    error InvalidReceiverAddress(address);
    error PaymentDeadlineExpired();
}