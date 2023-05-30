// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@gridexprotocol/core/contracts/interfaces/callback/IGridSwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Gridex
interface ISwapRouter is IGridSwapCallback {
    struct ExactInputSingleParameters {
        /// @dev Address of the input token
        address tokenIn;
        /// @dev Address of the output token
        address tokenOut;
        /// @dev The resolution of the pool to swap on
        int24 resolution;
        /// @dev Address to receive swapped tokens
        address recipient;
        /// @dev The deadline of the transaction execution
        uint256 deadline;
        /// @dev The amount of the input token to swap
        uint256 amountIn;
        /// @dev The minimum amount of the last token to receive. Reverts if actual amount received is less than this value.
        uint256 amountOutMinimum;
        /// @dev If zero for one, the price cannot be less than this value after the swap. If one for zero,
        /// the price cannot be greater than this value after the swap
        uint160 priceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param parameters The parameters necessary for the swap, encoded as `ExactInputSingleParameters` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParameters calldata parameters
    ) external payable returns (uint256 amountOut);

    struct ExactInputParameters {
        /// @dev Path of tokens to swap
        bytes path;
        /// @dev Address to receive swapped tokens
        address recipient;
        /// @dev The deadline of the transaction execution
        uint256 deadline;
        /// @dev The amount of the input token to swap
        uint256 amountIn;
        /// @dev The minimum amount of the last token to receive. Reverts if actual amount received is less than this value.
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param parameters The parameters necessary for the multi-hop swap, encoded as `ExactInputParameters` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParameters calldata parameters) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParameters {
        /// @dev Address of the input token
        address tokenIn;
        /// @dev Address of the output token
        address tokenOut;
        /// @dev The resolution of the pool to swap on
        int24 resolution;
        /// @dev Address to receive swapped tokens
        address recipient;
        /// @dev The deadline of the transaction execution
        uint256 deadline;
        /// @dev The amount of the output token to receive
        uint256 amountOut;
        /// @dev The maximum amount of input tokens to spend. Reverts if actual amount spent is greater than this value.
        uint256 amountInMaximum;
        /// @dev If zero for one, the price cannot be less than this value after the swap. If one for zero,
        /// the price cannot be greater than this value after the swap
        uint160 priceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param parameters The parameters necessary for the swap, encoded as `ExactOutputSingleParameters` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(
        ExactOutputSingleParameters calldata parameters
    ) external payable returns (uint256 amountIn);

    struct ExactOutputParameters {
        /// @dev Path of tokens to swap
        bytes path;
        /// @dev Address to receive swapped tokens
        address recipient;
        /// @dev The deadline of the transaction execution
        uint256 deadline;
        /// @dev The amount of the output token to receive
        uint256 amountOut;
        /// @dev The maximum amount of input tokens to spend. Reverts if actual amount spent is greater than this value.
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param parameters The parameters necessary for the multi-hop swap, encoded as `ExactOutputParameters` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParameters calldata parameters) external payable returns (uint256 amountIn);
}