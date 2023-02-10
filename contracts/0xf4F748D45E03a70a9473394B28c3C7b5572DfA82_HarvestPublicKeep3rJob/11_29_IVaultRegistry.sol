// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVaultRegistry {
  // solhint-disable-next-line func-name-mixedcase
  function DEFAULT_VAULT_TYPE() external view returns (uint256);

  // solhint-disable-next-line func-name-mixedcase
  function LEGACY_REGISTRY() external view returns (address);

  function approvedVaultsOwner(address) external view returns (bool);

  function endorseVault(address _vault) external;

  function endorseVault(
    address _vault,
    uint256 _releaseDelta,
    uint256 _type
  ) external;

  function endorseVault(address _vault, uint256 _releaseDelta) external;

  function isRegistered(address) external view returns (bool);

  function isVaultEndorsed(address) external view returns (bool);

  function latestVault(address _token) external view returns (address);

  function latestVaultOfType(address _token, uint256 _type) external view returns (address);

  function newVault(
    address _token,
    address _governance,
    address _guardian,
    address _rewards,
    string memory _name,
    string memory _symbol,
    uint256 _releaseDelta,
    uint256 _type
  ) external returns (address);

  function newVault(
    address _token,
    address _guardian,
    address _rewards,
    string memory _name,
    string memory _symbol,
    uint256 _releaseDelta
  ) external returns (address);

  function numTokens() external view returns (uint256);

  function numVaults(address _token) external view returns (uint256);

  function owner() external view returns (address);

  function releaseRegistry() external view returns (address);

  function renounceOwnership() external;

  function setApprovedVaultsOwner(address _addr, bool _approved) external;

  function setVaultEndorsers(address _addr, bool _approved) external;

  function tokens(uint256) external view returns (address);

  function transferOwnership(address _newOwner) external;

  function updateReleaseRegistry(address _newRegistry) external;

  function vaultEndorsers(address) external view returns (bool);

  function vaultType(address) external view returns (uint256);

  function vaults(address, uint256) external view returns (address);
}