// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.21;

interface IInbox {
    /// @notice Put an message in the L2 inbox that can be reexecuted for some fixed amount of time
    ///     if it reverts all msg.value will deposited to callValueRefundAddress on L2
    /// @param destAddr_ Destination L2 contract address
    /// @param arbTxCallValue_ Call value for retryable L2 message
    /// @param maxSubmissionCost_ Max gas deducted from user's L2 balance to cover base submission fee
    /// @param submissionRefundAddress_ maxGas x gasprice - execution cost gets credited here on L2 balance
    /// @param valueRefundAddress_ l2Callvalue gets credited here on L2 if retryable txn times out or gets cancelled
    /// @param maxGas_ Max gas deducted from user's L2 balance to cover L2 execution
    /// @param gasPriceBid_ Price bid for L2 execution
    /// @param data_ ABI encoded data of L2 message
    /// @return unique id for retryable transaction (keccak256(requestID, uint(0) )
    function createRetryableTicket(
        address destAddr_,
        uint256 arbTxCallValue_,
        uint256 maxSubmissionCost_,
        address submissionRefundAddress_,
        address valueRefundAddress_,
        uint256 maxGas_,
        uint256 gasPriceBid_,
        bytes calldata data_
    ) external payable returns (uint256);

    /// @notice Returns address of the Arbitumr's bridge
    function bridge() external view returns (address);
}