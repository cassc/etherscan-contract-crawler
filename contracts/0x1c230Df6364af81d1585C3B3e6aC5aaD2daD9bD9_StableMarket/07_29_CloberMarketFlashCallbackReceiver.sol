// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface CloberMarketFlashCallbackReceiver {
    /**
     * @notice To use `flash()`, the user must implement this method.
     * The user will receive the requested tokens via the `OrderBook.flash()` function before this method.
     * In this method, the user must repay the loaned tokens plus fees, or the transaction will revert.
     * @param quoteToken The quote token address.
     * @param baseToken The base token address.
     * @param quoteAmount The amount of quote tokens the user has borrowed.
     * @param baseAmount The amount of base tokens the user has borrowed.
     * @param quoteFeeAmount The fee amount in quote tokens for borrowing quote tokens.
     * @param baseFeeAmount The fee amount in base tokens for borrowing base tokens.
     * @param data The user's custom callback data.
     */
    function cloberMarketFlashCallback(
        address quoteToken,
        address baseToken,
        uint256 quoteAmount,
        uint256 baseAmount,
        uint256 quoteFeeAmount,
        uint256 baseFeeAmount,
        bytes calldata data
    ) external;
}