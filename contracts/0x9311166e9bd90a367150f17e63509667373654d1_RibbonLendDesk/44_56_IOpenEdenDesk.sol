// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IOpenEdenDesk
 * @author AlloyX
 */
interface IOpenEdenDesk {
  /**
   * @notice Get the USDC value of the OpenEden wallet
   * @param _vaultAddress the vault address of which we calculate the balance
   */
  function getOpenEdenWalletUsdcValue(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Deposit treasury USDC to OpenEden tranche vault
   * @param _vaultAddress the vault address
   * @param _address the address of tranche vault
   * @param _amount the amount to deposit
   */
  function depositToOpenEden(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external;

  /**
   * @notice Withdraw USDC from OpenEden Tranche portfolio and deposit to treasury
   * @param _vaultAddress the vault address
   * @param _address the address of Tranche portfolio
   * @param _amount the amount to withdraw in USDC
   * @return shares to burn during withdrawal https://github.com/trusttoken/contracts-carbon/blob/c9694396fc01c851a6c006d65c9e3420af723ee2/contracts/TrancheVault.sol#L262
   */
  function withdrawFromOpenEden(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external returns (uint256);

  /**
   * @notice Get the USDC value of the OpenEden wallet on one tranche vault address
   * @param _vaultAddress the pool address of which we calculate the balance
   * @param _address the address of Tranche portfolio
   */
  function getOpenEdenWalletUsdcValueOfPortfolio(address _vaultAddress, address _address) external view returns (uint256);

  /**
   * @notice Get the OpenEden Pool addresses for the alloyx vault
   * @param _vaultAddress the vault address
   */
  function getOpenEdenVaultAddressesForAlloyxVault(address _vaultAddress) external view returns (address[] memory);

  /**
   * @notice Get the OpenEden Vault balance for the alloyx vault
   * @param _vaultAddress the address of alloyx vault
   * @param _OpenEdenVault the address of OpenEden vault
   */
  function getOpenEdenVaultShareForAlloyxVault(address _vaultAddress, address _OpenEdenVault) external view returns (uint256);
}