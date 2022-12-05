// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.16;

import "CommonConstants.sol";
import "AccessControl.sol";

/**
  This contract handles the StarkNet Token global timelock.
  The Global Timelock is applied on all the locked token grants.
  Before the global timelock expires, all the locked token grants, are 100% locked,
  regardless of grant size and elapsed time since grant start time.
  Once the timelock expires, the amount of locked tokens in the grant is determined by the size
  of the grant and its start time.

  The global time-lock can be changed by an admin. To perform that,
  the admin must hold the GLOBAL_TIMELOCK_ADMIN_ROLE rights on the `LockedTokenCommon` contract.
  The global time-lock can be reset to a new timestamp as long as the following conditions are met:
  i. The new timestamp is in the future with at least a minimal margin.
  ii. The new timestamp does not exceed the global time-lock upper bound.
  iii. The global time-lock has not expired yet.

  The deployed LockedTokenGrant contracts query this contract to read the global timelock.
*/
abstract contract GlobalUnlock is AccessControl {
    uint256 internal immutable UPPER_LIMIT_GLOBAL_TIME_LOCK;
    uint256 public globalUnlockTime;

    event GlobalUnlockTimeUpdate(
        uint256 oldUnlockTime,
        uint256 newUnlockTime,
        address indexed sender
    );

    constructor() {
        UPPER_LIMIT_GLOBAL_TIME_LOCK = block.timestamp + MAX_DURATION_GLOBAL_TIMELOCK;
        _updateGlobalLock(block.timestamp + DEFAULT_DURATION_GLOBAL_TIMELOCK);
    }

    function updateGlobalLock(uint256 unlockTime) external onlyRole(GLOBAL_TIMELOCK_ADMIN_ROLE) {
        require(unlockTime > block.timestamp + MIN_UNLOCK_DELAY, "SELECTED_TIME_TOO_EARLY");
        require(unlockTime < UPPER_LIMIT_GLOBAL_TIME_LOCK, "SELECTED_TIME_EXCEED_LIMIT");

        require(block.timestamp < globalUnlockTime, "GLOBAL_LOCK_ALREADY_EXPIRED");
        _updateGlobalLock(unlockTime);
    }

    /*
      Setter for the globalUnlockTime.
      See caller function code for update logic, validation and restrictions.
    */
    function _updateGlobalLock(uint256 newUnlockTime) internal {
        emit GlobalUnlockTimeUpdate(globalUnlockTime, newUnlockTime, msg.sender);
        globalUnlockTime = newUnlockTime;
    }
}