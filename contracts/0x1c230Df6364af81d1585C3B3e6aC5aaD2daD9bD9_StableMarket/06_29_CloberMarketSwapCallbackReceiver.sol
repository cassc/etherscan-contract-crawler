// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface CloberMarketSwapCallbackReceiver {
    /**
     * @notice Contracts placing orders on the OrderBook must implement this method.
     * In this method, the contract has to send the required token, or the transaction will revert.
     * If there is a claim bounty to be refunded, it will be transferred via msg.value.
     * @param inputToken The address of the token the user has to send.
     * @param outputToken The address of the token the user has received.
     * @param inputAmount The amount of tokens the user has to send.
     * @param outputAmount The amount of tokens the user has received.
     * @param data The user's custom callback data.
     */
    function cloberMarketSwapCallback(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        bytes calldata data
    ) external payable;
}