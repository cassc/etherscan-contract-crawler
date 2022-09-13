// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IMapleDesk {
  /**
   * @notice Maple Wallet Value in term of USDC
   */
  function getMapleWalletUsdcValue() external view returns (uint256);
}