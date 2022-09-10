// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

/// @notice Stores votes and rewards delegation mapping in DelegateFunction
struct DelegateMapView {
    bytes32 functionId;
    address otherParty;
    bool mustRelinquish;
    bool pending;
}