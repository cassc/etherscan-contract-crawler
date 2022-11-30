// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRibbonDesk {
  /**
   * @notice Ribbon Wallet Value in term of USDC
   */
  function getRibbonWalletUsdcValue() external view returns (uint256);
}