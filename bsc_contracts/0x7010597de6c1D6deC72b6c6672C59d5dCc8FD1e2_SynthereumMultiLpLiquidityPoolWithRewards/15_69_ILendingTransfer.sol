// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Pool interface for making lending manager interacting with the pool
 */
interface ISynthereumLendingTransfer {
  /**
   * @notice Transfer a bearing amount to the lending manager
   * @notice Only the lending manager can call the function
   * @param _bearingAmount Amount of bearing token to transfer
   * @return bearingAmountOut Real bearing amount transferred to the lending manager
   */
  function transferToLendingManager(uint256 _bearingAmount)
    external
    returns (uint256 bearingAmountOut);
}