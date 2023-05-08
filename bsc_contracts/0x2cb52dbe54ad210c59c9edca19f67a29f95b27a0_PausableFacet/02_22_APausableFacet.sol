// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {WithPausable} from "./WithPausable.sol";
import {LibPausable} from "./LibPausable.sol";
import {IPausable} from "./IPausable.sol";

abstract contract APausableFacet is WithPausable {
  modifier onlyAuthorized() virtual {
    revert();
    _;
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function pause() external virtual whenNotPaused onlyAuthorized {
    LibPausable.pause();
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function unpause() external virtual whenPaused onlyAuthorized {
    LibPausable.unpause();
  }

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function isPaused() external view returns (bool) {
    return LibPausable.isPaused();
  }

  /**
   * @dev Returns the timestamp when the contract was paused.
   */
  function lastPausedAt() external view returns (uint256) {
    return LibPausable.lastPausedAt();
  }

  /**
   * @dev Returns the time since the contract was last paused.
   */
  function timeSincePaused() external view returns (uint256) {
    return LibPausable.timeSincePaused();
  }
}