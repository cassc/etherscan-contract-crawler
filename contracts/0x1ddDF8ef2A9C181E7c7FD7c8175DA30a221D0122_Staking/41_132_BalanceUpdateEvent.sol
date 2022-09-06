// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a users balance changes
struct BalanceUpdateEvent {
    bytes32 eventSig;
    address account;
    address token;
    uint256 amount;
}