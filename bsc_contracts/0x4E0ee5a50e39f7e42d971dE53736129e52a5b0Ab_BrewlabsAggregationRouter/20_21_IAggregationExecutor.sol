// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Interface for making arbitrary calls during swap
interface IAggregationExecutor {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function execute(address msgSender) external payable;  // 0x4b64e492
}