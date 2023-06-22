// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import { Ownable } from "./Ownable.sol";

contract LockableData {
    bool public locked;
}

contract Lockable is LockableData, Ownable {
    /**
     * @dev Locks functions with whenNotLocked modifier
     */
    function lock() external onlyOwner {
        locked = true;
    }

    /**
     * @dev Throws if called when unlocked.
     */
    modifier whenLocked() {
        require(locked, "Lockable: unlocked");
        _;
    }

    /**
     * @dev Throws if called after it was locked.
     */
    modifier whenNotLocked() {
        require(!locked, "Lockable: locked");
        _;
    }
}