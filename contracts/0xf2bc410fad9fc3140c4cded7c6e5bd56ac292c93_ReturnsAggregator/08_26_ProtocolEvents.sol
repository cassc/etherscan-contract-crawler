// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ProtocolEvents {
    /// @notice Emitted when a protocol configuration has been updated.
    /// @param setterSelector The selector of the function that updated the configuration.
    /// @param setterSignature The signature of the function that updated the configuration.
    /// @param value The abi-encoded data passed to the function that updated the configuration. Since this event will
    /// only be emitted by setters, this data corresponds to the updated values in the protocol configuration.
    event ProtocolConfigChanged(bytes4 indexed setterSelector, string setterSignature, bytes value);
}