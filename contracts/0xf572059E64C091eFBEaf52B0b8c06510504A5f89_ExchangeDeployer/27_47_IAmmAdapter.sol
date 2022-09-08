//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

/// @title IAmmAdapter interface.
/// @notice Implementations of this interface have all the details needed to interact with a particular AMM.
/// This pattern allows Futureswap to be extended to use several AMMs like UniswapV2 (and forks like Trader Joe),
/// UniswapV3, Trident, etc while keeping the details to connect to them outside of our core system.
interface IAmmAdapter {
    /// @notice Swaps `token1Amount` of `token1` for `token0`. If `token1Amount` is positive, then the `recipient`
    /// will receive `token1`, and if negative, they receive `token0`.
    /// @param recipient The recipient to send tokens to.
    /// @param token0 Must be one of the tokens the adapter supports.
    /// @param token1 Must be one of the tokens the adapter supports.
    /// @param token1Amount Amount of `token1` to swap. This method will revert if token1Amount is zero.
    /// @return token0Amount The amount of `token0` paid (negative) or received (positive).
    function swap(
        address recipient,
        address token0,
        address token1,
        int256 token1Amount
    ) external returns (int256 token0Amount);

    /// @notice Returns a spot price of exchanging 1 unit of token0 in units of token1.
    ///     Representation is fixed point integer with precision set by `FsMath.FIXED_POINT_BASED`
    ///     (defined to be `10**18`).
    ///
    /// @param token0 The token to return price for.
    /// @param token1 The token to return price relatively to.
    function getPrice(address token0, address token1) external view returns (int256 price);

    /// @notice Returns the tokens that this AMM adapter and underlying pool support. Order of the tokens should be the
    /// the same as the order defined by the AMM pool.
    function supportedTokens() external view returns (address[] memory tokens);
}