// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IClearPoolDesk {
  /**
   * @notice ClearPool Wallet Value in term of USDC
   */
  function getClearPoolWalletUsdcValue() external view returns (uint256);
}