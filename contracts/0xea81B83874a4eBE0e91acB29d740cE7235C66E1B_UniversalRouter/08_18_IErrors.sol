// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IErrors {
    error ThrowingError(bytes message);

    /// @notice Thrown when swap fails
    error FailedSwap();

    /// @notice Thrown when reserves are insufficient
    error InsufficientLiquidity();

    /// @notice Thrown when amountOut is insufficient
    error InsufficientOutput();

    /// @notice Thrown when ETH value does not equal amountIn
    error IncorrectETHValue();

    /// @notice Thrown if swapType is not exactInput in V3
    error BadSwapType();

    /// @notice Thrown when pool is incorrect in callback
    error BadPool();

    /// @notice Incorrect fromToken input
    error IncorrectFromToken();
}