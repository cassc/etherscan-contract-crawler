// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ITruefiDesk {
  /**
   * @notice Truefi Wallet Value in term of USDC
   */
  function getTruefiWalletUsdcValue() external view returns (uint256);
}