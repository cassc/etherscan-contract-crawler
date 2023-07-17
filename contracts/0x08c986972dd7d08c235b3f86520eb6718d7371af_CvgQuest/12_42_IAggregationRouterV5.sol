// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAggregationExecutor {
    function execute(address msgSender) external payable;
}

interface IAggregationRouterV5 {
    /// @dev swap data for 1inch when claiming rewards to perform a swap
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    /// @dev swap transaction data
    struct SwapTransaction {
        IAggregationExecutor executor;
        SwapDescription description;
        bytes permit;
        bytes data;
    }

    function swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 spentAmount);
}