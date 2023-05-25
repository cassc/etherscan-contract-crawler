// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IAntfarmPairEvents {
    /// @notice Emitted when a position's liquidity is removed
    /// @param sender The address that initiated the burn call
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    /// @param to The address to send token0 & token1
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that initiated the mint call
    /// @param amount0 Required token0 for the minted liquidity
    /// @param amount1 Required token1 for the minted liquidity
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call
    /// @param amount0In Amount of token0 sent to the pair
    /// @param amount1In Amount of token1 sent to the pair
    /// @param amount0Out Amount of token0 going out of the pair
    /// @param amount1Out Amount of token1 going out of the pair
    /// @param to Address to transfer the swapped amount
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    /// @notice Emitted by the pool for any call to Sync function
    /// @param reserve0 reserve0 updated from the pair
    /// @param reserve1 reserve1 updated from the pair
    event Sync(uint112 reserve0, uint112 reserve1);
}