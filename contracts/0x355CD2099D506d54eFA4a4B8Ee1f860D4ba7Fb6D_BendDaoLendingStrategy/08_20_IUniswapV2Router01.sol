// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title IUniswapV2Router01
/// @author Protectorate
/// @dev Interface for the Uniswap V2 Router 01.
interface IUniswapV2Router01 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory);
}