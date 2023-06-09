// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryState {
    /// @return Returns the address of the Native factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}