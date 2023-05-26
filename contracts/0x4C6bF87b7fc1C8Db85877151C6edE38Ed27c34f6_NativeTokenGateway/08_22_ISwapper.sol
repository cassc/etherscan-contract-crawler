// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ISwapper {
    function swapExactInput(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address receiver_
    ) external returns (uint256 _amountOut);
}