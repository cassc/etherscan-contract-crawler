// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IButtonswapRouterErrors {
    /// @notice Deadline was exceeded
    error Expired();
    /// @notice Insufficient amount of token A available
    error InsufficientAAmount();
    /// @notice Insufficient amount of token B available
    error InsufficientBAmount();
    /// @notice Neither token in the pool has the required reservoir
    error NoReservoir();
    /// @notice Pools are not initialized
    error NotInitialized();
    /// @notice Insufficient amount of token A in the reservoir
    error InsufficientAReservoir();
    /// @notice Insufficient amount of token B in the reservoir
    error InsufficientBReservoir();
    /// @notice Insufficient tokens returned from operation
    error InsufficientOutputAmount();
    /// @notice Required input amount exceeds specified maximum
    error ExcessiveInputAmount();
    /// @notice Invalid path provided
    error InvalidPath();
    /// @notice movingAveragePrice0 is out of specified bounds
    error MovingAveragePriceOutOfBounds();
}