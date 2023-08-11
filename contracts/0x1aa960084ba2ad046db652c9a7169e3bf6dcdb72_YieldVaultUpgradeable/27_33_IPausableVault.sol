// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IPausableVault
 *
 * @author Fujidao Labs
 *
 * @notice Defines the interface {PausableVault} contract.
 */

interface IPausableVault {
  enum VaultActions {
    Deposit,
    Withdraw,
    Borrow,
    Payback
  }

  /**
   * @dev Emit when pause of `action` is triggered by `account`.
   *
   * @param account who called the pause
   * @param action being paused
   */
  event Paused(address account, VaultActions action);
  /**
   * @dev Emit when the pause of `action` is lifted by `account`.
   *
   * @param account who called the unpause
   * @param action being paused
   */
  event Unpaused(address account, VaultActions action);
  /**
   * emit
   * @dev Emitted when forced pause all `VaultActions` triggered by `account`.
   *
   * @param account who called all pause
   */
  event PausedForceAll(address account);
  /**
   * @dev Emit when forced pause is lifted to all `VaultActions` by `account`.
   *
   * @param account who called the all unpause
   */
  event UnpausedForceAll(address account);

  /**
   * @notice Returns true if the `action` in contract is paused, otherwise false.
   *
   * @param action to check pause status
   */
  function paused(VaultActions action) external view returns (bool);

  /**
   * @notice Force pause state for all `VaultActions`.
   *
   * @dev Requirements:
   * - Must be implemented in child contract with access restriction.
   */
  function pauseForceAll() external;

  /**
   * @notice Force unpause state for all `VaultActions`.
   *
   * @dev Requirements:
   * - Must be implemented in child contract with access restriction.
   */
  function unpauseForceAll() external;

  /**
   * @notice Set paused state for `action` of this vault.
   *
   * @param action Enum: 0-deposit, 1-withdraw, 2-borrow, 3-payback
   *
   * Requirements:
   * - The `action` in contract must not be unpaused.
   * - Must be implemented in child contract with access restriction.
   */
  function pause(VaultActions action) external;

  /**
   * @notice Set unpause state for `action` of this vault.
   *
   * @param action Enum: 0-deposit, 1-withdraw, 2-borrow, 3-payback
   *
   * @dev Requirements:
   * - The `action` in contract must be paused.
   * - Must be implemented in child contract with access restriction.
   */
  function unpause(VaultActions action) external;
}