// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IVault} from "./IVault.sol";

/**
 * @title ILendingProvider
 *
 * @author Fujidao Labs
 *
 * @notice  Defines the interface for core engine to perform operations at lending providers.
 *
 * @dev Functions are intended to be called in the context of a Vault via delegateCall,
 * except indicated.
 */

interface ILendingProvider {
  function providerName() external view returns (string memory);
  /**
   * @notice Returns the operator address that requires ERC20-approval for vault operations.
   *
   * @param keyAsset address to inquiry operator
   * @param asset address of the calling vault
   * @param debtAsset address of the calling vault. Note: if {YieldVault} this will be address(0).
   *
   * @dev Provider implementations may or not require all 3 inputs.
   */
  function approvedOperator(
    address keyAsset,
    address asset,
    address debtAsset
  )
    external
    view
    returns (address operator);

  /**
   * @notice Performs deposit operation at lending provider on behalf vault.
   *
   * @param amount amount to deposit
   * @param vault IVault calling this function
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function deposit(uint256 amount, IVault vault) external returns (bool success);

  /**
   * @notice Performs borrow operation at lending provider on behalf vault.
   *
   * @param amount amount to borrow
   * @param vault IVault calling this function
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function borrow(uint256 amount, IVault vault) external returns (bool success);

  /**
   * @notice Performs withdraw operation at lending provider on behalf vault.
   * @param amount amount to withdraw
   * @param vault IVault calling this function.
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function withdraw(uint256 amount, IVault vault) external returns (bool success);

  /**
   *
   * @notice Performs payback operation at lending provider on behalf vault.
   *
   * @param amount amount to payback
   * @param vault IVault calling this function.
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   * - Check there is erc20-approval to `approvedOperator` by the `vault` prior to call.
   */
  function payback(uint256 amount, IVault vault) external returns (bool success);

  /**
   * @notice Returns DEPOSIT balance of 'user' at lending provider.
   *
   * @param user address whom balance is needed
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0).
   *
   * @dev Requirements:
   * - Must not require Vault context.
   */
  function getDepositBalance(address user, IVault vault) external view returns (uint256 balance);

  /**
   * @notice Returns BORROW balance of 'user' at lending provider.
   *
   * @param user address whom balance is needed
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0).
   *
   * @dev Requirements:
   * - Must not require Vault context.
   */
  function getBorrowBalance(address user, IVault vault) external view returns (uint256 balance);

  /**
   * @notice Returns the latest SUPPLY annual percent rate (APR) at lending provider.
   *
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0)
   *
   * @dev Requirements:
   * - Must return the rate in ray units (1e27)
   * Example 8.5% APR = 0.085 x 1e27 = 85000000000000000000000000
   * - Must not require Vault context.
   */
  function getDepositRateFor(IVault vault) external view returns (uint256 rate);

  /**
   * @notice Returns the latest BORROW annual percent rate (APR) at lending provider.
   *
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0)
   *
   * @dev Requirements:
   * - Must return the rate in ray units (1e27)
   * Example 8.5% APR = 0.085 x 1e27 = 85000000000000000000000000
   * - Must not require Vault context.
   */
  function getBorrowRateFor(IVault vault) external view returns (uint256 rate);
}