// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)
// Metadrop based on OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity 0.8.21;

import {Manager} from "./Manager.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (a manager) that can be granted exclusive access to
 * specific functions.
 *
 * The initial manager is specified at deployment time in the constructor for `Manager`. This
 * can later be changed with {transferManager} and {acceptManager}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Manager).
 */
abstract contract Manager2Step is Manager {
  address private _pendingManager;

  event ManagerTransferStarted(
    address indexed previousManager,
    address indexed newManager
  );

  /**
   * @dev Returns the address of the pending manager.
   */
  function pendingManager() public view virtual returns (address) {
    return _pendingManager;
  }

  /**
   * @dev Starts the manager transfer of the contract to a new account. Replaces the pending transfer if there is one.
   * Can only be called by the current manager.
   */
  function transferManager(
    address newManager
  ) public virtual override onlyManager {
    _pendingManager = newManager;
    emit ManagerTransferStarted(manager(), newManager);
  }

  /**
   * @dev Transfers manager of the contract to a new account (`newManager`) and deletes any pending manager.
   * Internal function without access restriction.
   */
  function _transferManager(address newManager) internal virtual override {
    delete _pendingManager;
    super._transferManager(newManager);
  }

  /**
   * @dev The new manager accepts the manager transfer.
   */
  function acceptManager() public virtual {
    address sender = _msgSender();
    if (pendingManager() != sender) {
      _revert(ManagerUnauthorizedAccount.selector);
    }
    _transferManager(sender);
  }
}