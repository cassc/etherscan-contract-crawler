// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

interface IPaymentNotaryV0 {
    event PaymentSent(
        address indexed from,
        address indexed to,
        bytes32 indexed orderId,
        address currency,
        uint256 amount
    );

    // msg.sender pays the receiver and emits PaymentSent event above
    function pay(
        address receiver,
        bytes32 orderId,
        address currency,
        uint256 amount
    ) external payable;
}

interface IPaymentNotaryV1 {
    event PaymentSent(
        string namespace,
        address indexed from,
        address indexed to,
        bytes32 indexed paymentReference,
        address currency,
        uint256 paymentAmount
    );

    // msg.sender pays the receiver and emits PaymentSent event above
    function pay(
        string calldata namespace,
        address receiver,
        bytes32 paymentReference,
        address currency,
        uint256 paymentAmount
    ) external payable;
}

interface IPaymentNotaryV2 {
    event PaymentSent(
        string namespace,
        address indexed from,
        address indexed to,
        bytes32 indexed paymentReference,
        address currency,
        uint256 paymentAmount,
        uint256 feeAmount,
        uint256 deadline
    );

    // msg.sender pays the receiver and emits PaymentSent event above
    function pay(
        string calldata namespace,
        address receiver,
        bytes32 paymentReference,
        address currency,
        uint256 paymentAmount,
        uint256 feeAmount,
        uint256 deadline
    ) external payable;

    function getFeeReceiver() external view returns (address feeReceiver);
}