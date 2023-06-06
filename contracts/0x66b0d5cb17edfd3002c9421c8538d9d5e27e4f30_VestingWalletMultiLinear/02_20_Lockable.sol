// SPDX-License-Identifier: MIT
// Unagi Contracts v1.0.0 (Lockable.sol)
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which allows children to implement a lock
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotLocked` and `whenLocked`, which can be applied to
 * the functions of your contract. Note that they will not be lockable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Lockable is Context {
    /**
     * @dev Emitted when the lock is triggered by `account` for `duration`.
     */
    event Locked(address account, uint256 duration);

    /**
     * @dev Emitted when the lock is triggered by `account` permanently.
     */
    event PermanentlyLocked(address account);

    bool private _permanentlyLocked;
    uint256 private _lockEnd;

    /**
     * @dev Initializes the contract in unlocked state.
     */
    constructor() {
        _permanentlyLocked = false;
        _lockEnd = 0;
    }

    /**
     * @dev Getter for the permanently locked.
     */
    function permanentlyLocked() public view virtual returns (bool) {
        return _permanentlyLocked;
    }

    /**
     * @dev Returns true if the contract is locked, and false otherwise.
     */
    function locked() public view virtual returns (bool) {
        return permanentlyLocked() || _lockEnd > block.timestamp;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not locked.
     *
     * Requirements:
     *
     * - The contract must not be locked.
     */
    modifier whenNotLocked() {
        require(!locked(), "Lockable: locked");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is locked.
     *
     * Requirements:
     *
     * - The contract must be locked.
     */
    modifier whenLocked() {
        require(locked(), "Lockable: not locked");
        _;
    }

    /**
     * @dev Getter for the lock end.
     *
     * Requirements:
     *
     * - The contract must be temporary locked.
     */
    function lockEnd() external view virtual whenLocked returns (uint256) {
        require(!permanentlyLocked(), "Lockable: not temporary locked");
        return _lockEnd;
    }

    /**
     * @dev Triggers locked state for a defined duration.
     *
     * Requirements:
     *
     * - The contract must not be locked.
     */
    function _lock(uint256 duration) internal virtual whenNotLocked {
        _lockEnd = block.timestamp + duration;
        emit Locked(_msgSender(), duration);
    }

    /**
     * @dev Triggers locked state permanently.
     *
     * Requirements:
     *
     * - The contract must not be locked.
     */
    function _permanentLock() internal virtual whenNotLocked {
        _permanentlyLocked = true;
        emit PermanentlyLocked(_msgSender());
    }
}