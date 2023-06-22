// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

/// @title Keep3r interface
/// @notice Exposes keep3r address
interface IKeeper3r {
    /// @notice Keep3r address
    /// @return Returns address of keep3r network
    function keep3r() external view returns (address);
}