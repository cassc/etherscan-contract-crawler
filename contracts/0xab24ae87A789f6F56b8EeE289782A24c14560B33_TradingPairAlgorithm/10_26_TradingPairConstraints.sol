// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

// @dev the trading pair constraints
struct TradingPairConstraints {
    /// @dev disallows forward swap
    bool disableForwardSwap;
    /// @dev disallows back swap
    bool disableBackSwap;
}