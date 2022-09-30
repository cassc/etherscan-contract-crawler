// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @title meTokens Protocol Migration Registry interface
/// @author Carter Carlson (@cartercarlson)
interface IMigrationRegistry {
    /// @notice Event of approving a meToken migration route
    /// @param initialVault    Vault for meToken to start migration from
    /// @param targetVault     Vault for meToken to migrate to
    /// @param migration       Address of migration vault
    event Approve(address initialVault, address targetVault, address migration);

    /// @notice Event of unapproving a meToken migration route
    /// @param initialVault    Vault for meToken to start migration from
    /// @param targetVault     Vault for meToken to migrate to
    /// @param migration       Address of migration vault
    event Unapprove(
        address initialVault,
        address targetVault,
        address migration
    );

    /// @notice Approve a vault migration route
    /// @param initialVault    Vault for meToken to start migration from
    /// @param targetVault     Vault for meToken to migrate to
    /// @param migration       Address of migration vault
    function approve(
        address initialVault,
        address targetVault,
        address migration
    ) external;

    /// @notice Unapprove a vault migration route
    /// @param initialVault    Vault for meToken to start migration from
    /// @param targetVault     Vault for meToken to migrate to
    /// @param migration       Address of migration vault
    function unapprove(
        address initialVault,
        address targetVault,
        address migration
    ) external;

    /// @notice View to see if a specific migration route is approved
    /// @param initialVault Vault for meToken to start migration from
    /// @param targetVault  Vault for meToken to migrate to
    /// @param migration    Address of migration vault
    /// @return             True if migration route is approved, else false
    function isApproved(
        address initialVault,
        address targetVault,
        address migration
    ) external view returns (bool);
}