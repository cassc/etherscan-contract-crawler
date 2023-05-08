// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PausableStorage} from "./PausableStorage.sol";
import {LibPausable} from "./LibPausable.sol";

abstract contract WithPausable {
  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier whenNotPaused() {
    PausableStorage storage pauseStorage = LibPausable.DS();
    if (pauseStorage.paused) revert LibPausable.PausedError();
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  modifier whenPaused() {
    PausableStorage memory pauseStorage = LibPausable.DS();
    if (!pauseStorage.paused) revert LibPausable.NotPausedError();
    _;
  }
}