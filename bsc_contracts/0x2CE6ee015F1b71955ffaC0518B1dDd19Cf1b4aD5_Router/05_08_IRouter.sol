// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRouter {
    function addLiquidity(
        uint amount,
        address to,
        uint deadline
    ) external returns (uint liquidity);

    function removeLiquidity(
        uint liquidity,
        address to,
        uint deadline
    ) external returns (uint amount);

    function swap(
        address tokenIn,
        uint amountIn,
        address tokenOut,
        uint amountOutMin,
        address to,
        uint deadline
    ) external returns (uint amountOut);

    function deleverageAndSwap(
        uint224 start,
        uint224 end,
        address tokenIn,
        uint amountIn,
        address tokenOut,
        uint amountOutMin,
        address to,
        uint deadline
    ) external returns (uint amountOut);
}