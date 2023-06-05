// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

abstract contract SingleOptionPhysicalVaultStorageV1 {
    // Token details the vault is able to mint options against
    // Only uses TokenType and productId
    uint256 public goldenToken;
}

// We are following Compound's method of upgrading new contract implementations
// When we need to add new storage variables, we create a new version of VaultStorage
// e.g. VaultStorage<versionNumber>, so finally it would look like
// contract VaultStorage is VaultStorageV1, VaultStorageV2
abstract contract SingleOptionPhysicalVaultStorage is SingleOptionPhysicalVaultStorageV1 {}