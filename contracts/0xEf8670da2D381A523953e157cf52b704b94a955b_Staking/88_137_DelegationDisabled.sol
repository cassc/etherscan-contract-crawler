// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a user has disabled their delegation for voting or rewards
struct DelegationDisabled {
    bytes32 eventSig;
    address from;
    address to;
    bytes32 functionId;
}