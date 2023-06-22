// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title ICredixDesk
 * @author AlloyX
 */
interface ICredixDesk {
  /**
   * @notice Get the Usdc value of the credix wallet
   * @param _poolAddress the address of pool
   */
  function getCredixWalletUsdcValue(address _poolAddress) external view returns (uint256);

  /**
   * @notice Deposit the Usdc value
   * @param _vaultAddress the vault address
   * @param _amount the amount to transfer
   */
  function increaseUsdcValueForPool(address _vaultAddress, uint256 _amount) external;
}