// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRibbonLendDesk {
  /**
   * @notice Ribbon Lend Wallet Value in term of USDC
   */
  function getRibbonLendWalletUsdcValue() external view returns (uint256);
}