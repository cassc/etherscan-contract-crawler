// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IRibbonDesk
 * @author AlloyX
 */
interface IRibbonDesk {
  function getRibbonWalletUsdcValue(address _alloyxVault) external view returns (uint256);

  /**
   * @notice Get the Usdc value of the Ribbon wallet
   * @param _vaultAddress the address of alloyx vault
   */
  function getRibbonUsdcValueOfVault(address _vaultAddress, address _ribbonVault) external view returns (uint256);

  /**
   * @notice Deposits the `asset` from vault.
   * @param _vaultAddress the vault address
   * @param _amount is the amount of `asset` to deposit
   * @param _ribbonVault is the address of the vault
   */
  function deposit(
    address _vaultAddress,
    address _ribbonVault,
    uint256 _amount
  ) external;

  /**
   * @notice Initiates a withdrawal that can be processed once the round completes
   * @param _vaultAddress the vault address
   * @param _numShares is the number of shares to withdraw
   * @param _ribbonVault is the address of the vault
   */
  function initiateWithdraw(
    address _vaultAddress,
    address _ribbonVault,
    uint256 _numShares
  ) external;

  /**
   * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
   * @param _vaultAddress the vault address
   * @param _poolAddress the pool address
   */
  function completeWithdraw(address _vaultAddress, address _poolAddress) external;

  /**
   * @notice Withdraws the assets on the vault using the outstanding `DepositReceipt.amount`
   * @param _vaultAddress the vault address
   * @param _ribbonVault is the address of the vault
   * @param _amount is the amount to withdraw in USDC https://github.com/ribbon-finance/ribbon-v2/blob/e9270281c7aa7433851ecee7f326c37bce28aec1/contracts/vaults/YearnVaults/RibbonThetaYearnVault.sol#L236
   */
  function withdrawInstantly(
    address _vaultAddress,
    address _ribbonVault,
    uint256 _amount
  ) external;

  /**
   * @notice Get the Ribbon Pool addresses for the alloyx vault
   * @param _vaultAddress the vault address
   */
  function getRibbonVaultAddressesForAlloyxVault(address _vaultAddress) external view returns (address[] memory);

  /**
   * @notice Get the Ribbon Vault balance for the alloyx vault
   * @param _vaultAddress the address of alloyx vault
   * @param _ribbonVault the address of ribbon vault
   */
  function getRibbonVaultShareForAlloyxVault(address _vaultAddress, address _ribbonVault) external view returns (uint256);
}