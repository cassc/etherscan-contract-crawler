// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IQuote {
/// @notice Used for RFQ-T trades (intra-chain).
    struct RFQTQuote {
        /// @notice The HashflowPool to trade against.
        address pool;
        /**
         * @notice The external account to be debited / credited.
         * If pool funds are used, this should be address(0).
         */
        address externalAccount;
        /// @notice The recipient of the quoteToken at the end of the trade.
        address trader;
        /**
         * @notice The account making the trade, in a scenario where this
         * trade is composed, e.g. by a proxy contract. This is commonly
         * used by aggregators, where the trader is their contract, while
         * the effective trader is the user (and initial caller).
         *
         * This field is never used for fund-related logic in the contracts,
         * but it is used when checking for replay.
         */
        address effectiveTrader;
        /// @notice The token that the trader sells.
        address baseToken;
        /// @notice The token that the trader buys.
        address quoteToken;
        /**
         * @notice The amount of baseToken sold in this trade. The exchange rate
         * is going to be preserved as the maxQuoteTokenAmount / maxBaseTokenAmount ratio.
         *
         * Most commonly, effectiveBaseTokenAmount will == maxBaseTokenAmount.
         */
        uint256 effectiveBaseTokenAmount;
        /// @notice The max amount of baseToken sold.
        uint256 maxBaseTokenAmount;
        /// @notice The amount of quoteToken received when maxBaseTokenAmount is sold.
        uint256 maxQuoteTokenAmount;
        /// @notice The Unix timestamp (in seconds) when the quote expires.
        uint256 quoteExpiry;
        /// @notice The nonce used by this effectiveTrader.
        uint256 nonce;
        /// @notice Unique identifier for the quote.
        /// @dev Generated off-chain via a distributed UUID generator.
        bytes32 txid;
        /// @notice Signature provided by the market maker (EIP-191).
        bytes signature;
    }

    /// @notice Executes an RFQ-T trade.
    /**
     * @dev Quotes are checked based on:
     * - expiry (HashflowRouter level)
     * - signature (HashflowPool level)
     * - replay (HashflowPool level)
     */
    /// @param quote The quote data to be executed.
    function tradeSingleHop(RFQTQuote memory quote) external payable;
}