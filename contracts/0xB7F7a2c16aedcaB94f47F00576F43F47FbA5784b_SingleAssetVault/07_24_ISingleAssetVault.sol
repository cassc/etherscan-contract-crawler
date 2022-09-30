// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @title Single Asset Vault interface
/// @author Carter Carlson (@cartercarlson)
/// @dev This builds on the basic IVault
interface ISingleAssetVault {
    /// @notice Event of starting a meTokens' migration to a new vault
    /// @param meToken Address of meToken
    event StartMigration(address meToken);

    /// @notice After warmup period, if there's a migration vault,
    ///          send meTokens' collateral to the migration
    /// @dev Reentrancy guard not needed as no state changes after external call
    /// @param meToken Address of meToken
    function startMigration(address meToken) external;
}