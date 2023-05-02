// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.15;

/// @title EIP-5313 Light Contract Ownership Standard
interface EIP5313 {
    /// @notice Get the address of the owner
    /// @return The address of the owner
    function owner() external view returns (address);
}