// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISynapseRouter {
    struct SwapQuery {
        address swapAdapter;
        address tokenOut;
        uint256 minAmountOut;
        uint256 deadline;
        bytes rawParams;
    }

    function bridge(
        address to,
        uint256 chainId,
        address token,
        uint256 amount,
        SwapQuery memory originQuery,
        SwapQuery memory destQuery
    ) external payable;
}