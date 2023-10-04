// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IClearPoolDesk
 * @author AlloyX
 */
interface IClearPoolDesk {
  /**
   * @notice Get the Usdc value of the Clear Pool wallet
   * @param _vaultAddress the pool address of which we calculate the balance
   */
  function getClearPoolWalletUsdcValue(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Get the Usdc value of the Clear Pool wallet on one pool master address
   * @param _vaultAddress the pool address of which we calculate the balance
   * @param _address the address of pool master
   */
  function getClearPoolUsdcValueOfPoolMaster(address _vaultAddress, address _address) external view returns (uint256);

  /**
   * @notice Deposit treasury USDC to ClearPool pool master
   * @param _vaultAddress the vault address
   * @param _address the address of pool master
   * @param _amount the amount to deposit
   */
  function provide(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external returns (uint256);

  /**
   * @notice Withdraw USDC from ClearPool pool master
   * @param _vaultAddress the vault address
   * @param _address the address of pool master
   * @param _amount the amount to withdraw in pool master tokens
   */
  function redeem(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external returns (uint256);

  /**
   * @notice Get the ClearPool addresses for the alloyx vault
   * @param _vaultAddress the vault address
   */
  function getClearPoolAddressesForVault(address _vaultAddress) external view returns (address[] memory);

  /**
   * @notice Get the ClearPool balance for the alloyx vault
   * @param _vaultAddress the vault address
   * @param _address the address of pool master
   */
  function getClearPoolBalanceForVault(address _vaultAddress, address _address) external view returns (uint256);
}