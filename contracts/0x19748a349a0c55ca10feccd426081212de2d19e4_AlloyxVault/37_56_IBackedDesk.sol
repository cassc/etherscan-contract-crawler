// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IBackedDesk
 * @author AlloyX
 */
interface IBackedDesk {
  /**
   * @notice Deposit USDC to the desk and prepare for being taken to invest in Backed
   * @param _vaultAddress the address of vault
   * @param _amount the amount of USDC
   */
  function deposit(address _vaultAddress, uint256 _amount) external;

  /**
   * @notice Deposit USDC to the desk and prepare for being taken to invest in Backed
   * @param _vaultAddress the address of vault
   */
  function getBackedTokenValueInUsdc(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Get the amount of Backed token for vault
   * @param _vaultAddress the address of vault
   */
  function getConfirmedBackedTokenAmount(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Get pending values in USDC for vault
   * @param _vaultAddress the address of vault
   */
  function getPendingVaultUsdcValue(address _vaultAddress) external view returns (uint256);
}