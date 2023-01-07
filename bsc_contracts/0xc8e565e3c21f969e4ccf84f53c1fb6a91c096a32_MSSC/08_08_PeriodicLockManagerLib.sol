// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.4;

/**
 * @title   LockManagerLib
 *
 * @notice  Library for managing hash-time Locks from Hybrid Settlement Cycles.
 */
library PeriodicLockManagerLib {
    event InitLock(bytes32 cycleId, bytes32 hashlock);
    event DisruptLock(bytes32 cycleId);
    event SecretRevealed(bytes32 cycleId, string secret);

    enum LockStatus {
        UNINITIALIZED,
        INITIALIZED,
        SECRET_REVEALED
    }

    struct PeriodicLockInfo {
        bytes32 hashlock;
        LockStatus status;
    }

    struct PeriodicLockConfig {
        uint256 originTimestamp;
        uint256 periodInHours;
        uint256 lockDurationInHours;
    }

    /**
     * @notice Record hashlock derived from a secret.
     * @dev    This function must be called once an Hybrid Settlement Cycle is being registered as the
     *         {hashlock} property will determine whether a cycle is hybrid or not.
     *
     * @param  lock Storage pointer of the lock of a cycle.
     * @param  hashlock_ hashlock to be set, will be used to validate secrets sent to MSSC.
     */
    function storeHashlock(
        PeriodicLockInfo storage lock,
        bytes32 hashlock_
    ) internal {
        if (lock.hashlock != bytes32(0)) {
            revert AlreadyCommited();
        }
        if (hashlock_ == bytes32(0)) {
            revert HashlockIsZero();
        }

        lock.hashlock = hashlock_;
    }

    /**
     * @notice Initialize absolute time-lock periods for a Settlement Cycle.
     *
     * @dev    Lock period is intended to allow claims, executions and secret revelation
     *         as long as the correct secret is provided. On the other hand, Unlock period is
     *         mean to allow withdrawls (hence disrupt the lock).
     *
     * @dev    This function must be called once all required deposits are fulfilled.
     *
     * @param  lock Storage pointer of the lock of a cycle.
     * @param  cycleId Cycle that owns the lock, used purely for log purposes.
     */
    function init(PeriodicLockInfo storage lock, bytes32 cycleId) internal {
        if (lock.status != LockStatus.UNINITIALIZED) {
            revert AlreadyInitialized();
        }
        lock.status = LockStatus.INITIALIZED;

        emit InitLock(cycleId, lock.hashlock);
    }

    /**
     * @notice Disrupt time-lock periods for a Cycle.
     * @dev    This function must be called once a withdrawal is made while lock's status is INITIALIZED.
     *
     * @param  lock Storage pointer of the lock of a cycle.
     * @param  cycleId Cycle that owns the lock, used purely for log purposes.
     */
    function disrupt(
        PeriodicLockInfo storage lock,
        bytes32 cycleId,
        PeriodicLockConfig memory lockConfig
    ) internal {
        if (isLocked(lock, lockConfig)) revert Locked();

        lock.status = LockStatus.UNINITIALIZED;

        emit DisruptLock(cycleId);
    }

    /**
     * @notice Reveal Lock's secret and infinitely extend claimable period.
     *
     * @dev    This method must be called when a cycle is within locked period and
     *         before performing any logic that requires being within the claimable period.
     * @dev    Once the secret is known, subsequent calls to {claim} or {executeInstuctions}
     *         may not require the secret to be sent in calldata anymore.
     *
     * @param  lock Storage pointer of the lock of a cycle.
     * @param  cycleId Cycle that owns the lock, used purely for log purposes.
     * @param  secret String to be validated against stored hashlock.
     */
    function validateSecret(
        PeriodicLockInfo storage lock,
        bytes32 cycleId,
        string calldata secret
    ) internal {
        if (_hash(secret) != lock.hashlock) {
            revert InvalidSecret();
        }

        lock.status = LockStatus.SECRET_REVEALED;

        emit SecretRevealed(cycleId, secret);
    }

    function isLocked(
        PeriodicLockInfo memory lock,
        PeriodicLockConfig memory lockConfig
    ) internal view returns (bool) {
        if (lock.status == LockStatus.UNINITIALIZED) return false;
        if (lock.status == LockStatus.SECRET_REVEALED) return true;

        unchecked {
            return
                ((block.timestamp - lockConfig.originTimestamp) %
                    lockConfig.periodInHours) < lockConfig.lockDurationInHours;
        }
    }

    function assertSecretIsRevealed(
        PeriodicLockInfo memory lock
    ) internal pure {
        if (lock.status != LockStatus.SECRET_REVEALED) {
            revert SecretNotRevealedYet();
        }
    }

    function assertIsNotLocked(
        PeriodicLockInfo memory lock,
        PeriodicLockConfig memory lockConfig
    ) internal view {
        if (isLocked(lock, lockConfig)) revert Locked();
    }

    function assertIsLockedPeriod(
        PeriodicLockInfo memory lock,
        PeriodicLockConfig memory lockConfig
    ) internal view {
        if (!isLocked(lock, lockConfig)) revert UnLocked();
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    function _hash(string calldata preimage) private pure returns (bytes32) {
        return sha256(abi.encodePacked(preimage));
    }

    function _getCurrentHour() private view returns (uint256) {
        return (block.timestamp % 1 days);
    }

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Revert with an error when a attempting interact with locked object.
     *
     */
    error Locked();

    /**
     * @dev Revert with an error when a attempting interact with unlocked object.
     *
     */
    error UnLocked();

    /**
     * @dev Revert with an error when a attempting to claim unlocked funds.
     *
     */
    error AlreadyInitialized();

    /**
     * @dev Revert with an error when a provided secret is incorrect.
     *
     */
    error InvalidSecret();

    /**
     * @dev Revert with an error when a provided hashlock is `bytes32(0)`.
     *
     */
    error HashlockIsZero();

    /**
     * @dev Revert with an error when a cycle has been already commited to be locked.
     *
     */
    error AlreadyCommited();

    /**
     * @dev Revert with an error when a cycle's lock has been already relocated.
     *
     */
    error SecretNotRevealedYet();
}