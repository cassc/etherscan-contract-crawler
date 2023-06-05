// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15
pragma solidity ^0.8.15;

import { IOwned } from "../IOwned.sol";

struct VaultMetadata {
  /// @notice Vault address
  address vault;
  /// @notice Staking contract for the vault
  address staking;
  /// @notice Owner and Vault creator
  address creator;
  /// @notice IPFS CID of vault metadata
  string metadataCID;
  /// @notice OPTIONAL - If the asset is an Lp Token these are its underlying assets
  address[8] swapTokenAddresses;
  /// @notice OPTIONAL - If the asset is an Lp Token its the pool address
  address swapAddress;
  /// @notice OPTIONAL - If the asset is an Lp Token this is the identifier of the exchange (1 = curve)
  uint256 exchange;
}

interface IVaultRegistry is IOwned {
  function getVault(address vault) external view returns (VaultMetadata memory);

  function getSubmitter(address vault) external view returns (address);

  function registerVault(VaultMetadata memory metadata) external;
}