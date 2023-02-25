// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

// =====================================================================
//
// |  \/  (_) |         | |                 |  _ \                   | |
// | \  / |_| | ___  ___| |_ ___  _ __   ___| |_) | __ _ ___  ___  __| |
// | |\/| | | |/ _ \/ __| __/ _ \| '_ \ / _ \  _ < / _` / __|/ _ \/ _` |
// | |  | | | |  __/\__ \ || (_) | | | |  __/ |_) | (_| \__ \  __/ (_| |
// |_|  |_|_|_|\___||___/\__\___/|_| |_|\___|____/ \__,_|___/\___|\__,_|
//
// =====================================================================
// ======================= IOwnerManager ===============================
// =====================================================================

/**
 * @title IOwnerManager
 * @author milestoneBased R&D Team
 *
 * @dev External interface of `OwnerManager`
 */
interface IOwnerManager {
  /**
   * @dev Throws if a certain field equal ZERO_ADDRESS, which shouldn't be
   */
  error ZeroAddress();

  /**
   * @dev Throws if try add exists owner
   */
  error OwnerDuplicate();

  /**
   * @dev Throws if newOwner address is incorrect.
   */
  error InvalidNewOwnerAddress();

  /**
   * @dev Throws if oldOwner address is incorrect.
   */
  error InvalidOldOwnerAddress();

  /**
   * @dev Throws if the sender is not the owner.
   */
  error NotOwnable(address);

  /**
   * @dev Throws if point to oldOwner provided is incorrect.
   */
  error InvalidPrevOwnerAddress();

  /**
   * @dev Emitted when `owner` is added to owners of contract.
   */
  event AddedOwner(address indexed owner);

  /**
   * @dev Emitted when `owner` is removed from owners of contract.
   */
  event RemovedOwner(address indexed owner);

  /**
   * @dev Transfers ownership of the contract from `oldOwner_` to a new account (`newOwner_`).
   *
   * @param prevOwner_ Owner which pointed to `oldOwner_` in linkedlist
   *
   * WARNING: owner can change other owners
   *
   * Requirements:
   *
   * - can only be called by the one from owner
   * - `newOwner_` must be not equal: `ZERO_ADDRESS`, `_SENTINEL_OWNERS`, this contract address
   *
   * Emits a {AddedOwner} and {RemovedOwner} events.
   */
  function swapOwner(
    address prevOwner_,
    address oldOwner_,
    address newOwner_
  ) external;

  /**
   * @dev Returns the status of whether the `owner_` is actual owner of contract
   *
   * Returns types:
   * - `false` - if `owner_` is not one from owners
   * - `true` - if `owner_` is one from owners
   */
  function isOwner(address owner_) external view returns (bool);

  /**
   * @dev Returns the addresses of the current owners.
   */
  function getOwners() external view returns (address[] memory result);
}