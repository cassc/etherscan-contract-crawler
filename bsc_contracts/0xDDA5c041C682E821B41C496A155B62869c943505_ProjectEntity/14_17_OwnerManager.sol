// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity =0.8.9;

//Smart Contract to manage owner rights
//Copyright (C) 2022 Safe Ecosystem https://github.com/safe-global

// =====================================================================
//
// |  \/  (_) |         | |                 |  _ \                   | |
// | \  / |_| | ___  ___| |_ ___  _ __   ___| |_) | __ _ ___  ___  __| |
// | |\/| | | |/ _ \/ __| __/ _ \| '_ \ / _ \  _ < / _` / __|/ _ \/ _` |
// | |  | | | |  __/\__ \ || (_) | | | |  __/ |_) | (_| \__ \  __/ (_| |
// |_|  |_|_|_|\___||___/\__\___/|_| |_|\___|____/ \__,_|___/\___|\__,_|
//
// =====================================================================
// ======================= OwnerManager ================================
// =====================================================================

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../interfaces/IOwnerManager.sol";

/**
 * @title OwnerManager
 * @author milestoneBased R&D Team, Safe Ecosystem
 *
 * @dev abstract contract which implemented the {IOwnerManager} interface. Responsible for
 * managing a set of owners
 *
 * This is a reworked shortened and updated version of OwnerManager.sol from GnosisSafe
 *
 * The contract inherits {ContextUpgradeable} from the OpenZeppelin contracts
 * so it is also upgradeable for future expansion
 */

abstract contract OwnerManager is IOwnerManager, ContextUpgradeable {
  /**
   * @dev Constant indicating the beginning and ending of the list
   */
  address internal constant _SENTINEL_OWNERS = address(0x1);

  /**
   * @dev Variable for storing count of owners
   */
  uint256 internal _ownerCount;

  /**
   * @dev Mapping for storing the reference between addresses in the linked list
   */
  mapping(address => address) internal _owners;

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (!_isOwner(_msgSender())) {
      revert NotOwnable(_msgSender());
    }
    _;
  }

  /**
   * @dev Initializes the contract setting the owner_ as the initial owner.
   *
   * Requirements:
   *
   * - `owner_` must not be equal to `ZERO_ADDRESS`, `_SENTINEL_OWNERS`, this contract address
   *
   * Emits a {AddedOwner} event.
   */
  // solhint-disable-next-line
  function __OwnerManager_init(address owner_)
    internal
    virtual
    onlyInitializing
  {
    if (
      owner_ == address(0) ||
      owner_ == _SENTINEL_OWNERS ||
      owner_ == address(this)
    ) {
      revert InvalidNewOwnerAddress();
    }

    _owners[_SENTINEL_OWNERS] = owner_;
    _owners[owner_] = _SENTINEL_OWNERS;

    unchecked {
      _ownerCount++;
    }

    emit AddedOwner(owner_);
  }

  /**
   * @dev Transfers ownership of the contract from `oldOwner_` to a new account (`newOwner_`).
   *
   * @param prevOwner_ Owner which points to `oldOwner_` in linkedlist
   *
   * WARNING: owner can change other owners
   *
   * Requirements:
   *
   * - can be called only by owner
   * - `newOwner_` must not be equal to `ZERO_ADDRESS`, `_SENTINEL_OWNERS`, this contract address
   *
   * Emits a {AddedOwner} and {RemovedOwner} events.
   */
  // solhint-disable-next-line ordering
  function swapOwner(
    address prevOwner_,
    address oldOwner_,
    address newOwner_
  ) external virtual override onlyOwner {
    _swapOwner(prevOwner_, oldOwner_, newOwner_);
  }

  /**
   * @dev Returns the status of whether the `owner_` is actual owner of contract
   *
   * Returns types:
   * - `false` - if `owner_` is not one from owners
   * - `true` - if `owner_` is one from owners
   */
  function isOwner(address owner_)
    external
    view
    virtual
    override
    returns (bool)
  {
    return _isOwner(owner_);
  }

  /**
   * @dev Returns the addresses of the current owners.
   */
  function getOwners()
    external
    view
    virtual
    override
    returns (address[] memory result)
  {
    result = new address[](_ownerCount);

    uint256 index;
    address currentOwner = _owners[_SENTINEL_OWNERS];
    while (currentOwner != _SENTINEL_OWNERS) {
      result[index] = currentOwner;
      currentOwner = _owners[currentOwner];
      unchecked {
        ++index;
      }
    }
  }

  /**
   * @dev Transfers ownership of the contract from `oldOwner_` to a new account (`newOwner_`).
   *
   * @param prevOwner_ Owner which points to `oldOwner_` in linkedlist
   *
   * [IMPORTANT]
   * ===
   * Internal function without access restriction
   * ===
   *
   * Requirements:
   *
   * - `newOwner_` must not be equal to `ZERO_ADDRESS`, `_SENTINEL_OWNERS`, this contract address
   *
   * Emits a {AddedOwner} and {RemovedOwner} events.
   */
  function _swapOwner(
    address prevOwner_,
    address oldOwner_,
    address newOwner_
  ) internal virtual {
    if (
      newOwner_ == address(0) ||
      newOwner_ == _SENTINEL_OWNERS ||
      newOwner_ == address(this)
    ) {
      revert InvalidNewOwnerAddress();
    }
    if (_owners[newOwner_] != address(0)) {
      revert OwnerDuplicate();
    }
    if (oldOwner_ == address(0) || oldOwner_ == _SENTINEL_OWNERS) {
      revert InvalidOldOwnerAddress();
    }
    if (_owners[prevOwner_] != oldOwner_) {
      revert InvalidPrevOwnerAddress();
    }

    _owners[newOwner_] = _owners[oldOwner_];
    _owners[prevOwner_] = newOwner_;
    delete _owners[oldOwner_];

    emit RemovedOwner(oldOwner_);
    emit AddedOwner(newOwner_);
  }

  /**
   * @dev Returns the status of whether the `owner_` is actual owner of contract
   *
   * Returns types:
   * - `false` - if `owner_` is not one from owners
   * - `true` - if `owner_` is one from owners
   */
  function _isOwner(address owner_) internal view virtual returns (bool) {
    return owner_ != _SENTINEL_OWNERS && _owners[owner_] != address(0);
  }

  /**
   * @dev Returns the first owner
   */
  function _getFirstOwner() internal view virtual returns (address) {
    return _owners[_SENTINEL_OWNERS];
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  // solhint-disable-next-line ordering
  uint256[50] private ___gap;
}