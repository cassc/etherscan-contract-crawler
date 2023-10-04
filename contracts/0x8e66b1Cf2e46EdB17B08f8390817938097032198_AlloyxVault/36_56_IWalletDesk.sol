// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IWalletDesk
 * @author AlloyX
 */
interface IWalletDesk {
  /**
   * @notice Get the Usdc value of the credix wallet
   * @param _poolAddress the address of pool
   */
  function getWalletUsdcValue(address _poolAddress) external view returns (uint256);

  /**
   * @notice Set the Usdc value
   * @param _vaultAddress the vault address
   * @param _amount the amount to transfer
   */
  function setUsdcValueForPool(address _vaultAddress, uint256 _amount) external;

  /**
   * @notice Withdraw the Usdc value
   * @param _vaultAddress the vault address
   * @param _amount the amount to transfer
   */
  function withdrawUsdc(address _vaultAddress, uint256 _amount) external;
}