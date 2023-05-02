// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 */
interface IPoolAddressesProvider {
  /**
   * @notice Returns the address of the Pool proxy.
   * @return The Pool proxy address
   */
  function getPool() external view returns (address);
}