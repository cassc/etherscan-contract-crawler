// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ILeechSwapper {
    /**
     * @notice Transfer an amount of the base token to the contract, then swap it for LP token according to the provided `baseToToken0` path.
     * @param amount The amount of base token to transfer.
     * @param lpAddr The address of the liquidity pool to deposit the swapped tokens into.
     * @param baseToToken0 The array of addresses representing the token contracts involved in the swap from the base token to the target token.
     */
    function leechIn(
        uint256 amount,
        address lpAddr,
        address[] memory baseToToken0
    ) external;

    /**
     *@notice Swaps out token from the liquidity pool to underlying base token
     *@param amount The amount of the token to be leeched out from liquidity pool.
     *@param lpAddr Address of the liquidity pool.
     *@param token0toBasePath Path of token0 in the liquidity pool to underlying base token.
     *@param token1toBasePath Path of token1 in the liquidity pool to underlying base token.
     */
    function leechOut(
        uint256 amount,
        address lpAddr,
        address[] memory token0toBasePath,
        address[] memory token1toBasePath
    ) external;

    /**
     * @notice Swap an amount of tokens for an equivalent amount of another token, according to the provided `path` of token contracts.
     * @param amountIn The amount of tokens being swapped.
     * @param path The array of addresses representing the token contracts involved in the swap.
     * @return swapedAmounts The array of amounts in the respective token after the swap.
     */
    function swap(
        uint256 amountIn,
        address[] memory path
    ) external payable returns (uint256[] memory swapedAmounts);

    /// @dev Insufficient ERC20 allowance
    error InsufficientAllowance();

    /// @dev Insufficient function input amount
    error InsufficientAmount();

    /// @dev Insufficient amount of token0
    error InsufficientAmountA();

    /// @dev Insufficient amount of token1
    error InsufficientAmountB();

    /// @dev Wrong token in the path array
    error WrongPath();

    /// @dev Insufficient pair reserves
    error LowReserves();

    /// @dev Wrong input function arguments
    error WrongArgument();
}