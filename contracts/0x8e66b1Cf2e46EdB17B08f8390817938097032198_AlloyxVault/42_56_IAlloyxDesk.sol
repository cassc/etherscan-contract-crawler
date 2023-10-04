// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IAlloyxDesk
 * @author AlloyX
 */
interface IAlloyxDesk {
  /**
   * @notice Purchase Alloyx
   * @param _vaultAddress the vault address
   * @param _amount the amount of usdc to purchase by
   */
  function deposit(address _vaultAddress, uint256 _amount) external;

  /**
   * @notice Withdraw ALLOYX V1
   * @param _vaultAddress the vault address
   * @param _amount the amount of ALLOYX V1 to sell
   */
  function withdraw(address _vaultAddress, uint256 _amount) external;

  /**
   * @notice Fidu Value in Vault in term of USDC
   * @param _vaultAddress the pool address of which we calculate the balance
   */
  function getAlloyxBalanceInUsdc(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Alloyx Balance in Vault in term
   * @param _vaultAddress the pool address
   */
  function getAlloyxBalance(address _vaultAddress) external view returns (uint256);
}