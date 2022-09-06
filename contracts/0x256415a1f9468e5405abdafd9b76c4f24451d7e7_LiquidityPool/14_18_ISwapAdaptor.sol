// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "../structures/SwapRequest.sol";

interface ISwapAdaptor {
    function swap(
        address inputTokenAddress,
        uint256 amountInMaximum,
        address receiver,
        SwapRequest[] calldata swapRequests
    ) external returns (uint256 amountIn);

    function swapNative(
        uint256 amountInMaximum,
        address receiver,
        SwapRequest[] calldata swapRequests
    ) external returns (uint256 amountOut);
}