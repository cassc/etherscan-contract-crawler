// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/**
 * @title IBIBOracle interface
 * @notice Interface for the BIB oracle.
 **/

interface IBIBOracle {
  function BASE_CURRENCY() external view returns (address);

  function BASE_CURRENCY_UNIT() external view returns (uint256);

  function getAssetPrice(address asset) external view returns (uint256);
}