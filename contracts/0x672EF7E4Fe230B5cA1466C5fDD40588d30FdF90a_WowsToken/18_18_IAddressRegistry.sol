/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

interface IAddressRegistry {
  /**
   * @dev Set an abitrary key / address pair into the registry
   */
  function setRegistryEntry(bytes32 _key, address _location) external;

  /**
   * @dev Get an registry enty with by key, returns 0 address if not existing
   */
  function getRegistryEntry(bytes32 _key) external view returns (address);
}