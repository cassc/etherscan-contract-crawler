// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

interface IUniswapV2Router01V5 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}