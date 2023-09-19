// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IxsLocker.sol";

/**
 * @title IxsListener
 * @author solace.fi
 * @notice A standard interface for notifying a contract about an action in another contract.
 */
interface IxsListener {
    /**
     * @notice Called when an action is performed on a lock.
     * @dev Called on transfer, mint, burn, and update.
     * Either the owner will change or the lock will change, not both.
     * @param xsLockID The ID of the lock that was altered.
     * @param oldOwner The old owner of the lock.
     * @param newOwner The new owner of the lock.
     * @param oldLock The old lock data.
     * @param newLock The new lock data.
     */
    function registerLockEvent(uint256 xsLockID, address oldOwner, address newOwner, Lock memory oldLock, Lock memory newLock) external;
}