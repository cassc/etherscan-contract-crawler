// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)
// Metadrop based on OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity 0.8.19;

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
abstract contract TaxAdmin is IErrors, Revert, Context {
  address private _taxAdmin;

  event TaxAdminTransferred(
    address indexed previousTaxAdmin,
    address indexed newTaxAdmin
  );

  constructor() {}

  /**
   * @dev Throws if called by any account other than the tax admin.
   */
  modifier onlyTaxAdmin() {
    _checkTaxAdmin();
    _;
  }

  /**
   * @dev Returns the address of the current tax admin.
   */
  function taxAdmin() public view virtual returns (address) {
    return _taxAdmin;
  }

  /**
   * @dev Throws if the sender is not the tax admin.
   */
  function _checkTaxAdmin() internal view virtual {
    if (taxAdmin() != _msgSender()) {
      _revert(CallerIsNotTheTaxAdmin.selector);
    }
  }

  /**
   * @dev Leaves the contract without a tax admin. It will not be possible to call
   * `onlyTaxAdmin` functions. Can only be called by the current tax admin.
   *
   * NOTE: Renouncing taxAdmin will leave the contract without an tax admim,
   * thereby disabling any functionality that is only available to the tax admin.
   */
  function renounceTaxAdmin() public virtual onlyTaxAdmin {
    _transferTaxAdmin(address(0));
  }

  /**
   * @dev Transfers the tax admin of the contract to a new account (`newTaxAdmin`).
   * Can only be called by the current tax admin.
   */
  function transferTaxAdmin(address newTaxAdmin) public virtual onlyTaxAdmin {
    if (newTaxAdmin == address(0)) {
      _revert(CannotSetNewTaxAdminToTheZeroAddress.selector);
    }
    _transferTaxAdmin(newTaxAdmin);
  }

  /**
   * @dev Transfers the tax admin of the contract to a new account (`newTaxAdmin`).
   * Internal function without access restriction.
   */
  function _transferTaxAdmin(address newTaxAdmin) internal virtual {
    address oldTaxAdmin = _taxAdmin;
    _taxAdmin = newTaxAdmin;
    emit TaxAdminTransferred(oldTaxAdmin, newTaxAdmin);
  }
}