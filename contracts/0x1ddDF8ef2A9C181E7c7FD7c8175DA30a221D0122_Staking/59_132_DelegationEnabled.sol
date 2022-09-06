// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a user has enabled delegation for voting or rewards
struct DelegationEnabled {
    bytes32 eventSig;
    address from;
    address to;
    bytes32 functionId;
}