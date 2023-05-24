// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPriceOracleGetter interface
 * @notice Interface for the Sturdy price oracle.
 **/

interface IPriceOracleGetter {
  /**
   * @dev returns the asset price in ETH
   * @param asset the address of the asset
   * @return the ETH price of the asset
   **/
  function getAssetPrice(address asset) external view returns (uint256);

  /**
   * @dev Validate the oracle
   * @param asset the address of the asset
   **/
  function checkOracle(address asset) external;
}