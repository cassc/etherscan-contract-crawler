// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

struct PaymentInfo {
    address from;
    address to;
    address assetAddress;
    uint256 amount;
    uint256 withdrawAmount;
    uint256 orderId;
    uint256 paymentId;
    address withdrawAddress;
}

struct TaskInfo {
    address from;
    uint256 amount;
    uint256 orderId;
}