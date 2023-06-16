// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2023
pragma solidity ^0.8.17;

import {IAdapter} from "../IAdapter.sol";
import {ISwapRouter} from "../../integrations/uniswap/IUniswapV3.sol";
import {IUniswapConnectorChecker} from "./IUniswapConnectorChecker.sol";

interface IUniswapV3AdapterExceptions {
    /// @notice Thrown when sanity checks on a swap path fail
    error InvalidPathException();
}

/// @title Uniswap V3 Router adapter interface
/// @notice Implements logic allowing CAs to perform swaps via Uniswap V3
interface IUniswapV3Adapter is IAdapter, IUniswapConnectorChecker, IUniswapV3AdapterExceptions {
    /// @notice Swaps given amount of input token for output token through a single pool
    /// @param params Swap params, see `ISwapRouter.ExactInputSingleParams` for details
    /// @dev `params.recipient` is ignored since it can only be the credit account
    function exactInputSingle(ISwapRouter.ExactInputSingleParams calldata params) external;

    /// @notice Params for exact all input swap through a single pool
    /// @param tokenIn Input token
    /// @param tokenOut Output token
    /// @param fee Fee level of the pool to swap through
    /// @param deadline Maximum timestamp until which the transaction is valid
    /// @param rateMinRAY Minimum exchange rate between input and output tokens, scaled by 1e27
    /// @param sqrtPriceLimitX96 Maximum execution price, ignored if 0
    struct ExactAllInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        uint256 deadline;
        uint256 rateMinRAY;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps all balance of input token for output token through a single pool, disables input token
    /// @param params Swap params, see `ExactAllInputSingleParams` for details
    function exactAllInputSingle(ExactAllInputSingleParams calldata params) external;

    /// @notice Swaps given amount of input token for output token through multiple pools
    /// @param params Swap params, see `ISwapRouter.ExactInputParams` for details
    /// @dev `params.recipient` is ignored since it can only be the credit account
    /// @dev `params.path` must have at most 3 hops through registered connector tokens
    function exactInput(ISwapRouter.ExactInputParams calldata params) external;

    /// @notice Params for exact all input swap through multiple pools
    /// @param path Bytes-encoded swap path, see Uniswap docs for details
    /// @param deadline Maximum timestamp until which the transaction is valid
    /// @param rateMinRAY Minimum exchange rate between input and output tokens, scaled by 1e27
    struct ExactAllInputParams {
        bytes path;
        uint256 deadline;
        uint256 rateMinRAY;
    }

    /// @notice Swaps all balance of input token for output token through multiple pools, disables input token
    /// @param params Swap params, see `ExactAllInputParams` for details
    /// @dev `params.path` must have at most 3 hops through registered connector tokens
    function exactAllInput(ExactAllInputParams calldata params) external;

    /// @notice Swaps input token for given amount of output token through a single pool
    /// @param params Swap params, see `ISwapRouter.ExactOutputSingleParams` for details
    /// @dev `params.recipient` is ignored since it can only be the credit account
    function exactOutputSingle(ISwapRouter.ExactOutputSingleParams calldata params) external;

    /// @notice Swaps input token for given amount of output token through multiple pools
    /// @param params Swap params, see `ISwapRouter.ExactOutputParams` for details
    /// @dev `params.recipient` is ignored since it can only be the credit account
    /// @dev `params.path` must have at most 3 hops through registered connector tokens
    function exactOutput(ISwapRouter.ExactOutputParams calldata params) external;
}