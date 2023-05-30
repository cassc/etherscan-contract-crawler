// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IUniswapV2Router {
    function uniswapV2ExactInput(
        uint256 amountIn,
        uint256 amountOutMinimum,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountOut);

    function uniswapV2ExactOutput(
        uint256 amountOut,
        uint256 amountInMaximum,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountIn);
}