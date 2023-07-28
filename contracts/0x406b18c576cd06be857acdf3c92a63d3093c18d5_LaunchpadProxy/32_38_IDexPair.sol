// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

/// @title IDexPair
/// @author gotbit
interface IDexPair {
    /// @dev Returns the address of the first token of the pair.
    /// @return token0_ address of the token
    function token0() external view returns (address token0_);

    /// @dev Returns the address of the second token of the pair.
    /// @return token1_ address of the token
    function token1() external view returns (address token1_);

    /// @dev Returns the amount of tokens the pair has and the time they last changed.
    /// @return reserve0 amount of token0
    /// @return reserve1 amount of token1
    /// @return blockTimestampLast time of last change
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}