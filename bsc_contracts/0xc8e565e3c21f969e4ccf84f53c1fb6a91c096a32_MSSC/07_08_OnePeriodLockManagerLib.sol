// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.4;

/**
 * @title   LockManagerLib
 *
 * @notice  Library for managing hash-time Locks from Hybrid Settlement Cycles.
 */
library OnePeriodLockManagerLib {
    event InitLock(bytes32 cycleId, bytes32 hashlock, uint32 deadline);
    event DisruptLock(bytes32 cycleId);
    event SecretRevealed(bytes32 cycleId, string secret);

    //enum LockStatus {
    //    INITIALIZED,
    //    SECRET_REVEALED,
    //    FINISHED
    //}

    struct OnePeriodLockInfo {
        bytes32 hashlock;
        uint32 deadline;
        bool secretRevealed;
    }

    // uint256 internal constant LOCK_PERIOD = 24 hours;
    // uint256 internal constant DAILY_SECHEDULE = 0 hours;

    /**
     * @notice Record hashlock derived from a secret.
     * @dev    This function must be called once an Hybrid Settlement Cycle is being registered as the
     *         {hashlock} property will determine whether a cycle is hybrid or not.
     *
     * @param  lock Storage pointer of the lock of a cycle.
     * @param  hashlock_ hashlock to be set, will be used to validate secrets sent to MSSC.
     */
    // function storeHashlock(LockInfo storage lock, bytes32 hashlock_) internal {
    //     if (lock.hashlock != bytes32(0)) {
    //         revert AlreadyCommited();
    //     }
    //
    //     lock.hashlock = hashlock_;
    // }

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
    function init(
        OnePeriodLockInfo storage lock,
        bytes32 cycleId,
        bytes32 hashlock_,
        uint32 deadline
    ) internal {
        if (lock.hashlock != bytes32(0)) {
            revert AlreadyInitialized();
        }

        if (uint32(block.timestamp) >= deadline) {
            revert InvalidDeadline();
        }

        if (hashlock_ == bytes32(0)) {
            revert HashlockIsZero();
        }

        lock.hashlock = hashlock_;
        lock.deadline = deadline;

        emit InitLock(cycleId, hashlock_, deadline);
    }

    /**
     * @notice Disrupt time-lock periods for a Cycle.
     * @dev    This function must be called once a withdrawal is made while lock's status is INITIALIZED.
     *
     * @param  lock Storage pointer of the lock of a cycle.
     * @param  cycleId Cycle that owns the lock, used purely for log purposes.
     */
    // function disrupt(LockInfo storage lock, bytes32 cycleId) internal {
    //     if (isLocked(lock)) revert Locked();
    //
    //     lock.status = LockStatus.UNINITIALIZED;
    //
    //     emit DisruptLock(cycleId);
    // }

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
        OnePeriodLockInfo storage lock,
        bytes32 cycleId,
        string calldata secret
    ) internal {
        if (_hash(secret) != lock.hashlock) {
            revert InvalidSecret();
        }

        lock.secretRevealed = true;

        emit SecretRevealed(cycleId, secret);
    }

    function isLocked(
        OnePeriodLockInfo memory lock
    ) internal view returns (bool) {
        return (uint32(block.timestamp) < lock.deadline) || lock.secretRevealed;
    }

    function assertSecretIsRevealed(
        OnePeriodLockInfo memory lock
    ) internal pure {
        if (!lock.secretRevealed) {
            revert SecretNotRevealedYet();
        }
    }

    function assertIsNotLocked(OnePeriodLockInfo memory lock) internal view {
        if (isLocked(lock)) revert Locked();
    }

    function assertIsLocked(OnePeriodLockInfo memory lock) internal view {
        if (!isLocked(lock)) revert UnLocked();
    }

    function isExpired(
        OnePeriodLockInfo memory lock
    ) internal view returns (bool) {
        return (uint32(block.timestamp) >= lock.deadline);
    }

    function assertIsNotExpired(OnePeriodLockInfo memory lock) internal view {
        if (isExpired(lock)) revert LockExpired();
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    function _hash(string calldata preimage) private pure returns (bytes32) {
        return sha256(abi.encodePacked(preimage));
    }

    // function _getCurrentTime() private view returns (uint256) {
    //     return (block.timestamp % 1 days);
    // }

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
     * @dev Revert with an error when a attempting to claim unlocked funds.
     *
     */
    error InvalidDeadline();

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
     * @dev Revert with an error when a cycle's lock has been already relocated.
     *
     */
    error SecretNotRevealedYet();

    /**
     * @dev Revert with an error when a cycle's lock has been expired.
     *
     */
    error LockExpired();
}