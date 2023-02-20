pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT

interface ISwapHelper {
        function swap(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) external returns (uint256 result);
}