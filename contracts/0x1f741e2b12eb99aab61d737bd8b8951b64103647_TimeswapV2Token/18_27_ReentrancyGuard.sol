// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title library for renentrancy protection
/// @author Timeswap Labs
library ReentrancyGuard {
  /// @dev Reverts when their is a reentrancy to a single option.
  error NoReentrantCall();

  /// @dev Reverts when the option, pool, or token id is not interacted yet.
  error NotInteracted();

  /// @dev The initial state which must be change to NOT_ENTERED when first interacting.
  uint96 internal constant NOT_INTERACTED = 0;

  /// @dev The initial and ending state of balanceTarget in the Option struct.
  uint96 internal constant NOT_ENTERED = 1;

  /// @dev The state where the contract is currently being interacted with.
  uint96 internal constant ENTERED = 2;

  /// @dev Check if there is a reentrancy in an option.
  /// @notice Reverts when balanceTarget is not zero.
  /// @param reentrancyGuard The balance being inquired.
  function check(uint96 reentrancyGuard) internal pure {
    if (reentrancyGuard == NOT_INTERACTED) revert NotInteracted();
    if (reentrancyGuard == ENTERED) revert NoReentrantCall();
  }
}