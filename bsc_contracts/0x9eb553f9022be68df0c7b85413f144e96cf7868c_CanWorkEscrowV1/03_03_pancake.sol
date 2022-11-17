// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

// PancekeSwap Interface
interface IPancakeRouter01 {
    // Swaps BEP20 tokens for another BEP20 token via PancakeSwap pairs
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    // Swaps BNB for a BEP20 token via PancakeSwap pairs
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}