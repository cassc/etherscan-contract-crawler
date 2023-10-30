// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

/**
 * @title A place for common modifiers and functions used by various Worlds mixins, if any.
 * @author HardlyDifficult
 */
abstract contract WorldsCore {
  /**
   * @notice This empty reserved space is put in place to allow future versions to add new variables without shifting
   * down storage in the inheritance chain. See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev This file uses a total of 10,000 slots.
   */
  uint256[10_000] private __gap;
}