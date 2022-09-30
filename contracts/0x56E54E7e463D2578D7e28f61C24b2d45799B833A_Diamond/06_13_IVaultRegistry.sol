// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @title meTokens Protocol Vault Registry interface
/// @author Carter Carlson (@cartercarlson)
interface IVaultRegistry {
    /// @notice Event of approving an address
    /// @param addr Address to approve
    event Approve(address addr);

    /// @notice Event of unapproving an address
    /// @param addr Address to unapprove
    event Unapprove(address addr);

    /// @notice Approve an address
    /// @param addr Address to approve
    function approve(address addr) external;

    /// @notice Unapprove an address
    /// @param addr Address to unapprove
    function unapprove(address addr) external;

    /// @notice View to see if an address is approved
    /// @param addr     Address to view
    /// @return         True if address is approved, else false
    function isApproved(address addr) external view returns (bool);
}