// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title Helpers for working with time.
 * @author batu-inal & HardlyDifficult
 */
library TimeLibrary {
  /**
   * @notice Checks if the given timestamp is in the past.
   * @dev This helper ensures a consistent interpretation of expiry across the codebase.
   * This is different than `hasBeenReached` in that it will return false if the expiry is now.
   */
  function hasExpired(uint256 expiry) internal view returns (bool) {
    return expiry < block.timestamp;
  }

  /**
   * @notice Checks if the given timestamp is now or in the past.
   * @dev This helper ensures a consistent interpretation of expiry across the codebase.
   * This is different from `hasExpired` in that it will return true if the timestamp is now.
   */
  function hasBeenReached(uint256 timestamp) internal view returns (bool) {
    return timestamp <= block.timestamp;
  }
}