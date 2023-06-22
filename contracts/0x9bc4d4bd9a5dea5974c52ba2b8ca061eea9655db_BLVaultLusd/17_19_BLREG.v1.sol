// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import "src/Kernel.sol";

/// @title  Olympus Boosted Liquidity Vault Registry
/// @notice Olympus Boosted Liquidity Vault Registry (Module) Contract
/// @dev    The Olympus Boosted Liquidity Vault Registry Module tracks the boosted liquidity vaults
///         that are approved to be used by the Olympus protocol. This allows for a single-soure
///         of truth for reporting purposes around total OHM deployed and net emissions.
abstract contract BLREGv1 is Module {
    // ========= EVENTS ========= //

    event VaultAdded(address indexed vault);
    event VaultRemoved(address indexed vault);

    // ========= STATE ========= //

    /// @notice Count of active vaults
    /// @dev    This is a useless variable in contracts but useful for any frontends or
    ///         off-chain requests where the array is not easily accessible.
    uint256 public activeVaultCount;

    /// @notice Tracks all active vaults
    address[] public activeVaults;

    // ========= FUNCTIONS ========= //

    /// @notice         Adds an vault to the registry
    /// @param vault_   The address of the vault to add
    function addVault(address vault_) external virtual;

    /// @notice         Removes an vault from the registry
    /// @param vault_   The address of the vault to remove
    function removeVault(address vault_) external virtual;
}