pragma solidity 0.8.19;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (common/CommonEventsAndErrors.sol)

/// @notice A collection of common errors thrown within the Temple contracts
library CommonEventsAndErrors {
    error InsufficientBalance(address token, uint256 required, uint256 balance);
    error InvalidParam();
    error InvalidAddress();
    error InvalidAccess();
    error InvalidAmount(address token, uint256 amount);
    error ExpectedNonZero();
    error Unimplemented();
    event TokenRecovered(address indexed to, address indexed token, uint256 amount);
}