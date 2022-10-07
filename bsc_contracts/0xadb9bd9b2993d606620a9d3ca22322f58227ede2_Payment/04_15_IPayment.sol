// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../Common.sol";

interface IPayment {
    function processPayment(PaymentInfo memory paymentInfo) external;
}