// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.18;

import "../../interfaces/internal/INFTSupplyLock.sol";
import "../../libraries/TimeLibrary.sol";

import "../roles/MinterRole.sol";
import "../shared/Constants.sol";

/// @param supplyLockExpiration The time at which supply is no longer locked.
error SupplyLock_Action_Disallowed_While_Supply_Is_Locked(uint256 supplyLockExpiration);
/// @param supplyLockHolder The address of the account holding the supply lock.
/// @param supplyLockExpiration The time at which supply is no longer restricted.
error SupplyLock_Caller_Is_Not_Supply_Lock_Holder(address supplyLockHolder, uint256 supplyLockExpiration);
error SupplyLock_Existing_Lock_Has_Already_Expired();
error SupplyLock_Expiration_Time_In_The_Past();
error SupplyLock_Expiration_Time_Too_Far_In_The_Future(uint256 maxExpiration);

/**
 * @title Allow collections to support restricting supply modifications to a single minter for a period of time.
 * @notice This is used to prevent supply changes during a sale - impacting mints by other users as well as preventing
 * changes to the max supply.
 * @dev The supply lock holder may have their minter role revoked, however they still maintain access until the
 * previously specified expiration.
 * @author HardlyDifficult
 */
abstract contract SupplyLock is INFTSupplyLock, MinterRole {
  using TimeLibrary for uint256;
  using TimeLibrary for uint40;

  /// @notice The time at which the supply is no longer restricted.
  /// @dev Expiration is specified first in order to pack with free storage in the previous mixin.
  uint40 private $supplyLockExpiration;

  /// @notice If set, only this address may mint tokens until the `supplyLockExpiration` has been reached.
  address private $supplyLock;

  /**
   * @notice Emitted when a supply lock has been granted to an approved minter.
   * @param supplyLock The address of the minter with the supply lock for a period of time.
   * @param supplyLockExpiration The time at which supply is no longer restricted.
   */
  event MinterAcquireSupplyLock(address indexed supplyLock, uint256 supplyLockExpiration);

  /**
   * @notice Reverts if a supply lock has been requested (and has not expired).
   */
  modifier notDuringSupplyLock() {
    if (!$supplyLockExpiration.hasExpired()) {
      revert SupplyLock_Action_Disallowed_While_Supply_Is_Locked($supplyLockExpiration);
    }
    _;
  }

  /**
   * @inheritdoc INFTSupplyLock
   */
  function minterAcquireSupplyLock(uint256 expiration) external hasPermissionToMint {
    if (expiration == 0) {
      /* CHECKS */

      // When expiration is 0, clear the supply lock configuration.
      if ($supplyLockExpiration.hasExpired()) {
        revert SupplyLock_Existing_Lock_Has_Already_Expired();
      }

      /* EFFECTS */

      delete $supplyLock;
      delete $supplyLockExpiration;

      emit MinterAcquireSupplyLock(address(0), 0);
    } else {
      /* CHECKS */

      if (expiration.hasExpired()) {
        revert SupplyLock_Expiration_Time_In_The_Past();
      }
      unchecked {
        // timestamp + 2 years can never realistically overflow 256 bits.
        if (expiration > block.timestamp + MAX_SCHEDULED_TIME_IN_THE_FUTURE) {
          revert SupplyLock_Expiration_Time_Too_Far_In_The_Future(block.timestamp + MAX_SCHEDULED_TIME_IN_THE_FUTURE);
        }
      }
      if (!$supplyLockExpiration.hasExpired() && expiration > $supplyLockExpiration) {
        // If the user is overwriting an existing configuration to increase the time left, confirm they have not had
        // their role revoked.
        super._requireCanMint();
      }

      /* EFFECTS */

      $supplyLock = msg.sender;
      // timestamp + 2 years will never realistically overflow 40 bits (sometime after year 36,000).
      $supplyLockExpiration = uint40(expiration);

      emit MinterAcquireSupplyLock(msg.sender, expiration);
    }
  }

  /**
   * @inheritdoc INFTSupplyLock
   */
  function getSupplyLock() external view returns (address supplyLockHolder, uint256 supplyLockExpiration) {
    supplyLockExpiration = $supplyLockExpiration;
    if (!supplyLockExpiration.hasExpired()) {
      supplyLockHolder = $supplyLock;
    } else {
      // Once expired, return (0x0, 0) instead of the stale data.
      supplyLockExpiration = 0;
    }
  }

  /**
   * @inheritdoc MinterRole
   * @dev This supplements the MinterRole implementation to enforce the supply lock if it has been requested.
   */
  function _requireCanMint() internal view virtual override {
    if (!$supplyLockExpiration.hasExpired()) {
      // When in the supply lock time period, require the caller is the supply lock holder.
      if ($supplyLock != msg.sender) {
        revert SupplyLock_Caller_Is_Not_Supply_Lock_Holder($supplyLock, $supplyLockExpiration);
      }
      // Skip the role check so that the supply lock holder's access cannot be revoked until the expiration.
    } else {
      // Otherwise, check the MinterRole permissions.
      super._requireCanMint();
    }
  }
}