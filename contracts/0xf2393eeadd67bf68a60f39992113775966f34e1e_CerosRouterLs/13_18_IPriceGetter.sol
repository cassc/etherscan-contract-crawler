// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPriceGetter {
    function getPrice(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96,
        uint24 fee
    ) external view returns (uint256 amountOut);
}