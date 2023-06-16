// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2023
pragma solidity ^0.8.17;

import {IAdapter} from "../IAdapter.sol";
import {IUniswapConnectorChecker} from "./IUniswapConnectorChecker.sol";

interface IUniswapV2AdapterExceptions {
    /// @notice Thrown when sanity checks on a swap path fail
    error InvalidPathException();
}

/// @title Uniswap V2 Router adapter interface
/// @notice Implements logic allowing CAs to perform swaps via Uniswap V2 and its forks
interface IUniswapV2Adapter is IAdapter, IUniswapConnectorChecker, IUniswapV2AdapterExceptions {
    /// @notice Swap input token for given amount of output token
    /// @param amountOut Amount of output token to receive
    /// @param amountInMax Maximum amount of input token to spend
    /// @param path Array of token addresses representing swap path, which must have at most 3 hops
    ///        through registered connector tokens
    /// @param deadline Maximum timestamp until which the transaction is valid
    /// @dev Parameter `to` is ignored since swap recipient can only be the credit account
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address,
        uint256 deadline
    ) external;

    /// @notice Swap given amount of input token to output token
    /// @param amountIn Amount of input token to spend
    /// @param amountOutMin Minumum amount of output token to receive
    /// @param path Array of token addresses representing swap path, which must have at most 3 hops
    ///        through registered connector tokens
    /// @param deadline Maximum timestamp until which the transaction is valid
    /// @dev Parameter `to` is ignored since swap recipient can only be the credit account
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address,
        uint256 deadline
    ) external;

    /// @notice Swap the entire balance of input token to output token, disables input token
    /// @param rateMinRAY Minimum exchange rate between input and output tokens, scaled by 1e27
    /// @param path Array of token addresses representing swap path, which must have at most 3 hops
    ///        through registered connector tokens
    /// @param deadline Maximum timestamp until which the transaction is valid
    function swapAllTokensForTokens(uint256 rateMinRAY, address[] calldata path, uint256 deadline) external;
}