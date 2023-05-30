// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Callback for IGrid#swap
/// @notice Any contract that calls IGrid#swap must implement this interface
interface IGridSwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IGrid#swap
    /// @dev In this implementation, you are required to pay the grid tokens owed for the swap.
    /// The caller of the method must be a grid deployed by the canonical GridFactory.
    /// If there is no token swap, both amount0Delta and amount1Delta are 0
    /// @param amount0Delta The grid will send or receive the amount of token0 upon completion of the swap.
    /// In the receiving case, the callback must send this amount of token0 to the grid
    /// @param amount1Delta The grid will send or receive the quantity of token1 upon completion of the swap.
    /// In the receiving case, the callback must send this amount of token1 to the grid
    /// @param data Any data passed through by the caller via the IGrid#swap call
    function gridexSwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}