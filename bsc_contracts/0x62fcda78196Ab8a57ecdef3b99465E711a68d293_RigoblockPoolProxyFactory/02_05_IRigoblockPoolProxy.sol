// SPDX-License-Identifier: Apache-2.0-or-later
pragma solidity >=0.8.0 <0.9.0;

interface IRigoblockPoolProxy {
    /// @notice Emitted when implementation written to proxy storage.
    /// @dev Emitted also at first variable initialization.
    /// @param newImplementation Address of the new implementation.
    event Upgraded(address indexed newImplementation);
}