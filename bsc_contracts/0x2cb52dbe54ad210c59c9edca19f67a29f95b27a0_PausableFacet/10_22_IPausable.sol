// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPausable {
  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function pause() external;

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function unpause() external;

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function isPaused() external view returns (bool);

  /**
   * @dev Returns the timestamp when the contract was paused.
   */
  function lastPausedAt() external view returns (uint256);

  /**
   * @dev Returns the time since the contract was last paused.
   */
  function timeSincePaused() external view returns (uint256);
}