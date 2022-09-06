// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice For contracts that provide liquidity to external protocols
 */
interface ILpAccount {
    /**
     * @notice Deploy liquidity with a registered `IZap`
     * @dev The order of token amounts should match `IZap.sortedSymbols`
     * @param name The name of the `IZap`
     * @param amounts The token amounts to deploy
     */
    function deployStrategy(string calldata name, uint256[] calldata amounts)
        external;

    /**
     * @notice Unwind liquidity with a registered `IZap`
     * @dev The index should match the order of `IZap.sortedSymbols`
     * @param name The name of the `IZap`
     * @param amount The amount of the token to unwind
     * @param index The index of the token to unwind into
     */
    function unwindStrategy(
        string calldata name,
        uint256 amount,
        uint8 index
    ) external;

    /**
     * @notice Return liquidity to a pool
     * @notice Typically used to refill a liquidity pool's reserve
     * @dev This should only be callable by the `MetaPoolToken`
     * @param pool The `IReservePool` to transfer to
     * @param amount The amount of the pool's underlyer token to transer
     */
    function transferToPool(address pool, uint256 amount) external;

    /**
     * @notice Swap tokens with a registered `ISwap`
     * @notice Used to compound reward tokens
     * @notice Used to rebalance underlyer tokens
     * @param name The name of the `IZap`
     * @param amount The amount of tokens to swap
     * @param minAmount The minimum amount of tokens to receive from the swap
     */
    function swap(
        string calldata name,
        uint256 amount,
        uint256 minAmount
    ) external;

    /**
     * @notice Claim reward tokens with a registered `IZap`
     * @param name The name of the `IZap`
     */
    function claim(string calldata name) external;
}