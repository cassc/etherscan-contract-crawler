//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IAmmAdapterCallback {
    /// @notice Adapter callback for collecting payment. Only one of the two tokens, stable or asset, can be positive,
    /// which indicates a payment due. Negative indicates we'll receive that token as a result of the swap.
    /// Implementations of this method should protect against malicious calls, and ensure that payments are triggered
    /// only by authorized contracts or as part of a valid trade flow.
    /// @param recipient The address to send payment to.
    /// @param token0 Token corresponding to amount0Owed.
    /// @param token1 Token corresponding to amount1Owed.
    /// @param amount0Owed Token amount in underlying decimals we owe for token0.
    /// @param amount1Owed Token amount in underlying decimals we owe for token1.
    function sendPayment(
        address recipient,
        address token0,
        address token1,
        int256 amount0Owed,
        int256 amount1Owed
    ) external;
}