// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./ISwapRouter.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV3Router.sol";

interface ISwapRouterHub is ISwapRouter, IUniswapV2Router, IUniswapV3Router {
    struct ExactMixedInputParameters {
        /// @dev The path of tokens to trade, encoded as SwapPath.
        bytes path;
        /// @dev The address that will receive the output tokens.
        address recipient;
        /// @dev The deadline of the transaction execution.
        uint256 deadline;
        /// @dev The amount of the first token to trade.
        uint256 amountIn;
        /// @dev The minimum amount of the last token to receive. Reverts if actual amount received is less than this value.
        uint256 amountOutMinimum;
    }

    /// @notice This function executes a mixed input swap transaction with the specified input parameters.
    /// @param parameters The parameters necessary for the swap, encoded as `ExactMixedInputParameters` in calldata
    /// @return amountOut The amount of the received token
    function exactMixedInput(
        ExactMixedInputParameters calldata parameters
    ) external payable returns (uint256 amountOut);
}