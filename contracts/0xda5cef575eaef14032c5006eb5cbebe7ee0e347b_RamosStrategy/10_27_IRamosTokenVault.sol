pragma solidity 0.8.19;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (interfaces/amo/helpers/IRamosTokenVault.sol)

/**
 * @title Ramos Token Vault
 *
 * @notice A vault to provide protocol and quote tokens to Ramos as it rebalances or updates liquidity.
 * These two tokens are the pair of tokens in a liquidity pool, eg:
 *   protocolToken = TEMPLE
 *   quoteToken = DAI
 */
interface IRamosTokenVault {
    /**
     * @notice Send `protocolToken` to recipient
     * @param amount The requested amount to borrow
     * @param recipient The recipient to send the `protocolToken` tokens to
     */
    function borrowProtocolToken(uint256 amount, address recipient) external;    

    /**
     * @notice Send `quoteToken` to recipient
     * @param amount The requested amount to borrow
     * @param recipient The recipient to send the `quoteToken` tokens to
     */
    function borrowQuoteToken(uint256 amount, address recipient) external;

    /**
     * @notice Pull `protocolToken` from the caller
     * @param amount The requested amount to repay
     */
    function repayProtocolToken(uint256 amount) external;

    /**
     * @notice Pull `quoteToken` from the caller
     * @param amount The requested amount to repay
     */
    function repayQuoteToken(uint256 amount) external;
}