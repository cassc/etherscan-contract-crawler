// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./IVersion.sol";

interface ISignerVaultFactoryV1 is IVersion {
  event VaultCreated(address indexed signer, address vault, uint length, uint signerLength);

  function contractDeployer() external view returns (address);
  function feeCollector() external view returns (address);
  function vault() external view returns (address);
  function signerVault() external view returns (address);

  function contains(address vault_) external view returns (bool);

  function vaults() external view returns (address[] memory);
  function vaultsLength() external view returns (uint);
  function getVault(uint index) external view returns (address);

  function vaultsOf(address signer) external view returns (address[] memory);
  function vaultsLengthOf(address signer) external view returns (uint);
  function getVaultOf(address signer, uint index) external view returns (address);

  function createVault(address signer) external returns (address);

  function addLinking(address newSigner) external;
  function removeLinking(address oldSigner) external;
}