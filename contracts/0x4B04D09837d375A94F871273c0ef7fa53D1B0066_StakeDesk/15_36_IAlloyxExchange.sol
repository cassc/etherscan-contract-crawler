// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAlloyxExchange {
  /**
   * @notice Convert Alloyx DURA to USDC amount
   * @param _amount the amount of DURA token to convert to usdc
   */
  function alloyxDuraToUsdc(uint256 _amount) external view returns (uint256);

  /**
   * @notice Convert USDC Amount to Alloyx DURA
   * @param _amount the amount of usdc to convert to DURA token
   */
  function usdcToAlloyxDura(uint256 _amount) external view returns (uint256);

  /**
   * @notice Alloy Treasury Value in terms of USDC
   */
  function getTreasuryTotalBalanceInUsdc() external view returns (uint256);
}