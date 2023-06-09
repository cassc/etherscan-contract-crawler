// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

abstract contract VariableUnderlyingVaultStorageV1 {}

// We are following Compound's method of upgrading new contract implementations
// When we need to add new storage variables, we create a new version of VaultStorage
// e.g. VaultStorage<versionNumber>, so finally it would look like
// contract VaultStorage is VaultStorageV1, VaultStorageV2
abstract contract VariableUnderlyingVaultStorage is VariableUnderlyingVaultStorageV1 {}