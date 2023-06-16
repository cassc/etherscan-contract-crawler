// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

/// @notice Interface for managing list of addresses permitted to perform preferred rate
///         arbitrage swaps on Cron-Fi TWAMM V1.0.
///
interface IArbitrageurList {
  /// @param sender is the address that called the function changing list owner permissions.
  /// @param listOwner is the address to change list owner permissions on.
  /// @param permission is true if the address specified in listOwner is granted list owner
  ///        permissions. Is false otherwise.
  ///
  event ListOwnerPermissions(address indexed sender, address indexed listOwner, bool indexed permission);

  /// @param sender is the address that called the function changing arbitrageur permissions.
  /// @param arbitrageurs is a list of addresses to change arbitrage permissions on.
  /// @param permission is true if the addresses specified in arbitrageurs is granted
  ///        arbitrage permissions. Is false otherwise.
  ///
  event ArbitrageurPermissions(address indexed sender, address[] arbitrageurs, bool indexed permission);

  /// @param sender is the address that called the function changing the next list address.
  /// @param nextListAddress is the address the return value of the nextList function is set to.
  ///
  event NextList(address indexed sender, address indexed nextListAddress);

  /// @notice Returns true if the provide address is permitted the preferred
  ///         arbitrage rate in the partner swap method of a Cron-Fi TWAMM pool.
  ///         Returns false otherwise.
  /// @param _address the address to check for arbitrage rate permissions.
  ///
  function isArbitrageur(address _address) external returns (bool);

  /// @notice Returns the address of the next contract implementing the next list of arbitrageurs.
  ///         If the return value is the NULL address, address(0), then the TWAMM contract's update
  ///         list method will keep the existing address it is storing to check for arbitrage permissions.
  ///
  function nextList() external returns (address);
}