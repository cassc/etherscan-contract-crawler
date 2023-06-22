// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.6;

/**
 * @author Balancer Labs (and OpenZeppelin)
 * @title Protect against reentrant calls (and also selectively protect view functions)
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {_lock_} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `_lock_` guard, functions marked as
 * `_lock_` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `_lock_` entry
 * points to them.
 *
 * Also adds a _lockview_ modifier, which doesn't create a lock, but fails
 *   if another _lock_ call is in progress
 */
contract ReentrancyGuard {
  // Booleans are more expensive than uint256 or any type that takes up a full
  // word because each write operation emits an extra SLOAD to first read the
  // slot's contents, replace the bits taken up by the boolean, and then write
  // back. This is the compiler's defense against contract upgrades and
  // pointer aliasing, and it cannot be disabled.

  // The values being non-zero value makes deployment a bit more expensive,
  // but in exchange the refund on every call to nonReentrant will be lower in
  // amount. Since refunds are capped to a percentage of the total
  // transaction's gas, it is best to keep them low in cases like this one, to
  // increase the likelihood of the full refund coming into effect.
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor() internal {
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `_lock_` function from another `_lock_`
   * function is not supported. It is possible to prevent this from happening
   * by making the `_lock_` function external, and make it call a
   * `private` function that does the actual work.
   */
  modifier lock() {
    // On the first call to _lock_, _notEntered will be true
    require(_status != _ENTERED, "ERR_REENTRY");

    // Any calls to _lock_ after this point will fail
    _status = _ENTERED;
    _;
    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Also add a modifier that doesn't create a lock, but protects functions that
   *      should not be called while a _lock_ function is running
   */
  modifier viewlock() {
    require(_status != _ENTERED, "ERR_REENTRY_VIEW");
    _;
  }
}