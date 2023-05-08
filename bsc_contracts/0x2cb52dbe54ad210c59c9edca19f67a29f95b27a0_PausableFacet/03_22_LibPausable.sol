// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PausableStorage} from "./PausableStorage.sol";

library LibPausable {
  using LibPausable for PausableStorage;

  bytes32 internal constant DIAMOND_STORAGE_POSITION =
    keccak256("diamond.standard.pausable.storage");

  error PausedError();
  error NotPausedError();

  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  function DS() internal pure returns (PausableStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function pause() internal {
    PausableStorage storage pauseStorage = LibPausable.DS();
    // set paused to true and store pausedAt
    pauseStorage.paused = true;
    pauseStorage.pausedAt = uint64(block.timestamp);
    emit Paused(msg.sender);
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function unpause() internal {
    PausableStorage storage pauseStorage = LibPausable.DS();
    pauseStorage.paused = false;
    emit Unpaused(msg.sender);
  }

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function isPaused() internal view returns (bool) {
    return LibPausable.DS().paused;
  }

  /**
   * @dev Returns the timestamp when the contract was last paused.
   */
  function lastPausedAt() internal view returns (uint64) {
    return LibPausable.DS().pausedAt;
  }

  /**
   * @dev Returns the time since the contract was last paused.
   */
  function timeSincePaused() internal view returns (uint256) {
    PausableStorage storage pauseStorage = LibPausable.DS();
    if (!pauseStorage.paused) return 0;
    return block.timestamp - pauseStorage.pausedAt;
  }
}