// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.17;


interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}