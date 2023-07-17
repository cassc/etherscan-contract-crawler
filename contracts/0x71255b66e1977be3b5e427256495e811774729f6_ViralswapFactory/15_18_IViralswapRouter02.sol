// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import './IUniswapRouter02.sol';

interface IViralswapRouter02 is IUniswapV2Router02 {

    function swapExactViralForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactViralForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForViralSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function buyTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function buyViralForExactTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function buyViralForExactETHSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function getVaultAmountOut(address tokenIn, address tokenOut, uint amountIn) external view returns (uint amountOut);
    function getVaultAmountIn(address tokenIn, address tokenOut, uint amountOut) external view returns (uint amountIn);
}