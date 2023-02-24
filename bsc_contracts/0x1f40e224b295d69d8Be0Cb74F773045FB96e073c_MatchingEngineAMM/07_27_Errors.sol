// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

/// @notice Mapping error code to error message
library Errors {
    string public constant ME_INITIALIZED = "ME_01";
    string public constant ME_ONLY_COUNTERPARTY = "ME_02";
    string public constant ME_INVALID_SIZE = "ME_03";
    string public constant ME_NOT_ENOUGH_LIQUIDITY = "ME_04";
    string public constant ME_INVALID_INPUT = "ME_05";
    string public constant ME_ONLY_PENDING_ORDER = "ME_06";
    string public constant ME_NOT_PASS_MARKET_MARKER = "ME_07";
    string public constant ME_MUST_CLOSE_TO_INDEX_PRICE_BUY = "ME_08";
    string public constant ME_MUST_CLOSE_TO_INDEX_PRICE_SELL = "ME_09";
    string public constant ME_MARKET_ORDER_MUST_CLOSE_TO_INDEX_PRICE = "ME_10";
    string public constant ME_SETTLE_FUNDING_TOO_EARLY = "ME_11";
    string public constant ME_INVALID_LEVERAGE = "ME_12";
    string public constant ME_LIMIT_OVER_PRICE_NOT_ENOUGH_LIQUIDITY = "ME_13";
}