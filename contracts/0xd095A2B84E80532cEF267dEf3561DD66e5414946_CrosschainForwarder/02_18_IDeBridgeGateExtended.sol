// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IDeBridgeGate.sol";

/// @dev This is a helper interface needed to access those properties that were accidentally
///      not included in the base IDeBridgeGate interface
interface IDeBridgeGateExtended is IDeBridgeGate {
    function callProxy() external returns (address);
    function globalFixedNativeFee() external returns (uint256);
    function globalTransferFeeBps() external returns (uint256);
}