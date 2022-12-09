// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// token swapper for AURA (tokenin => AURA)
interface ITokenSwapper {
    function swap(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 minAmountOut,
        bytes memory externalData
    ) external returns (uint256 amountOut);
}