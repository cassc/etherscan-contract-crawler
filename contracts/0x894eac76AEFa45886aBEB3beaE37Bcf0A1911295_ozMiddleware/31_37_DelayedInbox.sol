// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


interface DelayedInbox {
    function createRetryableTicket(
        address destAddr,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function sendL1FundedContractTransaction(
        uint256 maxGas, 
        uint256 gasPriceBid, 
        address destAddr, 
        bytes calldata data
    ) external payable returns (uint256);

    function sendL2MessageFromOrigin(bytes calldata messageData) external returns (uint256);
    function sendL2Message(bytes calldata messageData) external payable returns (uint256);

    function sendContractTransaction(
        uint256 maxGas, 
        uint256 gasPriceBid, 
        address destAddr, 
        uint256 amount, 
        bytes memory data
    ) external payable returns (uint256);

    function calculateRetryableSubmissionFee(
        uint256 dataLength, 
        uint256 baseFee
    ) external view returns (uint256);
}