// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.18;

/**
 * @title Allows an approved minter to lock down supply changes for a limited period of time.
 * @dev This is used to help ensure minting access and token supply are not manipulated during an active minting period.
 * @author HardlyDifficult
 */
interface INFTSupplyLock {
  /**
   * @notice Request a supply lock for a limited period of time.
   * @param expiration The date/time when the lock expires, in seconds since the Unix epoch.
   * @dev The caller must already be an approved minter.
   * If a lock has already been requested, it may be cleared by the lock holder by passing 0 for the expiration.
   */
  function minterAcquireSupplyLock(uint256 expiration) external;

  /**
   * @notice Get the current supply lock holder and expiration, if applicable.
   * @return supplyLockHolder The address of with lock access, or the zero address if supply is not locked.
   * @return supplyLockExpiration The date/time when the lock expires, in seconds since the Unix epoch. Returns 0 if a
   * lock has not been requested or if it has already expired.
   */
  function getSupplyLock() external view returns (address supplyLockHolder, uint256 supplyLockExpiration);
}