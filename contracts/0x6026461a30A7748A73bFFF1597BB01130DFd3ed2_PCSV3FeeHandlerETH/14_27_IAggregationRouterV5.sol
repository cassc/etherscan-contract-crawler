// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAggregationExecutor {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function execute(address msgSender) external payable;  // 0x4b64e492
}

interface IAggregationRouterV5 {
    struct SwapDescription {
        address srcToken;
        address dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    function swap(
        IAggregationExecutor executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    )
        external
        payable
        returns (
            uint256 returnAmount,
            uint256 spentAmount
        );
}