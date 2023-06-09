// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IMapleDesk
 * @author AlloyX
 */
interface IMapleDesk {
  /**
   * @notice Maple Wallet Value in term of USDC
   * @param _vaultAddress the vault address of which we calculate the balance
   */
  function getMapleWalletUsdcValue(address _vaultAddress) external view returns (uint256);

  /**
   * @notice Get the Usdc value of the truefi wallet
   * @param _vaultAddress the vault address of which we calculate the balance
   * @param _address the address of pool
   */
  function getMapleWalletUsdcValueOfPool(address _vaultAddress, address _address) external view returns (uint256);

  /**
   * @notice Get the Maple balance
   * @param _vaultAddress the vault address of which we calculate the balance
   * @param _address the address of pool
   */
  function getMapleBalanceOfPool(address _vaultAddress, address _address) external view returns (uint256);

  /**
   * @notice Transfer certain amount token of certain address to some other account
   * @param _account the address to transfer
   * @param _amount the amount to transfer
   * @param _tokenAddress the token address to transfer
   */
  function transferERC20(
    address _tokenAddress,
    address _account,
    uint256 _amount
  ) external;

  /**
   * @notice Deposit treasury USDC to Maple pool
   * @param _vaultAddress the vault address
   * @param _address the address of pool
   * @param _amount the amount to deposit
   */
  function depositToMaple(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external returns (uint256);

  /**
   * @notice Withdraw USDC from Maple managed portfolio and deposit to treasury
   * @param _vaultAddress the vault address
   * @param _address the address of pool
   * @param _amount the amount to withdraw in USDC
   */
  function withdrawFromMaple(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external returns (uint256);

  /**
   * @notice Initiate the countdown from the lockup period on Maple side
   * @param _vaultAddress the vault address
   */
  function requestWithdraw(
    address _vaultAddress,
    address _address,
    uint256 _shares
  ) external;

  /**
   * @notice Get the Maple Pool addresses for the alloyx vault
   * @param _vaultAddress the vault address
   */
  function getMaplePoolAddressesForVault(address _vaultAddress) external view returns (address[] memory);
}