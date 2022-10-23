// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    ) external returns (uint[] memory amountsOut);
}