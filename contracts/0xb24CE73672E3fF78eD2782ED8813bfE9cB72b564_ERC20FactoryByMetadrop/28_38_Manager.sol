// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)
// Metadrop based on OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity 0.8.21;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IErrors} from "./IErrors.sol";
import {Revert} from "./Revert.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Manager is IErrors, Revert, Context {
  address private _manager;

  event ManagerTransferred(
    address indexed previousManager,
    address indexed newManager
  );

  constructor() {}

  /**
   * @dev Throws if called by any account other than the manager.
   */
  modifier onlyManager() {
    _checkManager();
    _;
  }

  /**
   * @dev Returns the address of the current manager.
   */
  function manager() public view virtual returns (address) {
    return _manager;
  }

  /**
   * @dev Throws if the sender is not the manager.
   */
  function _checkManager() internal view virtual {
    if (manager() != _msgSender()) {
      _revert(CallerIsNotTheManager.selector);
    }
  }

  /**
   * @dev Leaves the contract without a manager. It will not be possible to call
   * `onlyManager` functions. Can only be called by the current manager.
   *
   * NOTE: Renouncing manager will leave the contract without an tax admim,
   * thereby disabling any functionality that is only available to the manager.
   */
  function renounceManager() public virtual onlyManager {
    _transferManager(address(0));
  }

  /**
   * @dev Transfers the manager of the contract to a new account (`newManager`).
   * Can only be called by the current manager.
   */
  function transferManager(address newManager) public virtual onlyManager {
    if (newManager == address(0)) {
      _revert(CannotSetNewManagerToTheZeroAddress.selector);
    }
    _transferManager(newManager);
  }

  /**
   * @dev Transfers the manager of the contract to a new account (`newManager`).
   * Internal function without access restriction.
   */
  function _transferManager(address newManager) internal virtual {
    address oldManager = _manager;
    _manager = newManager;
    emit ManagerTransferred(oldManager, newManager);
  }
}