//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @notice ITermPriceOracleEvents is an interface that defines all events emitted by the Term Price Oracle.
interface ITermPriceOracleEvents {
    /// @notice Event emitted when a new price feed is added or updated to price oracle.
    /// @param token The address of the token fee subscribe
    /// @param tokenPriceAggregator The proxy price aggregator address subscribed
    event SubscribePriceFeed(address token, address tokenPriceAggregator);

    /// @notice Event emitted when a price feed is removed from price oracle.
    /// @param token The address of the token
    event UnsubscribePriceFeed(address token);
}