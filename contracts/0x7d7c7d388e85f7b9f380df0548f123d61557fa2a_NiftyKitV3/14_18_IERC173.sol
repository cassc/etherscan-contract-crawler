// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC173 {
    /// @notice Get the address of the owner
    /// @return The address of the owner.
    function owner() external view returns (address);
}