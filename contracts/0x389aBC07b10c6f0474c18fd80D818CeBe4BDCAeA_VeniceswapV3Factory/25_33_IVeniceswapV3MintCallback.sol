// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IVeniceswapV3PoolActions#mint
/// @notice Any contract that calls IVeniceswapV3PoolActions#mint must implement this interface
interface IVeniceswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IVeniceswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a VeniceswapV3Pool deployed by the canonical VeniceswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IVeniceswapV3PoolActions#mint call
    function veniceswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}