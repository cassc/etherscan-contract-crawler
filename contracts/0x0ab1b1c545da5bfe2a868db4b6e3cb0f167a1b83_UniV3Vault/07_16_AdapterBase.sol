// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "../interfaces/IAdapter.sol";

/// @title Saffron Fixed Income Adapter
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice Foundational contract for building adapters which interface vaults to underlying yield-generating platforms
/// @dev Extend this abstract class to implement adapters
abstract contract AdapterBase is IAdapter {
  /// @notice Address of the vault associated with this adapter
  address public vaultAddress;

  /// @notice Address of the factory that created this adapter
  address public factoryAddress;

  constructor() {
    factoryAddress = msg.sender;
  }

  modifier onlyWithoutVaultAttached() {
    require(vaultAddress == address(0x0), "NVA");
    _;
  }

  modifier onlyFactory() {
    require(factoryAddress == msg.sender, "NF");
    _;
  }

  modifier onlyVault() {
    require(vaultAddress == msg.sender, "MBV");
    _;
  }

  /// @inheritdoc IAdapter
  function setVault(address _vaultAddress) virtual public override onlyWithoutVaultAttached onlyFactory {
    require(_vaultAddress != address(0), "NEI");
    vaultAddress = _vaultAddress;
  }

  /// @inheritdoc IAdapter
  function hasAccurateHoldings() virtual public view override returns (bool) {
    this;
    return true;
  }
}