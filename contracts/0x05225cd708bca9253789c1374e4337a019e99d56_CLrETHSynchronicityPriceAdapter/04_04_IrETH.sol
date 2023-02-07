// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice A simple version of the rETH interface allowing to get exchange rate with ETH
interface IrETH {
  /**
   * @notice Get the current ETH : rETH exchange rate
   * @return the amount of ETH backing 1 rETH
   */
  function getExchangeRate() external view returns (uint256);
}