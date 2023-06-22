// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import { Ownable } from "./Ownable.sol";

abstract contract LockableData {
    bool public locked;
}

abstract contract Lockable is LockableData, Ownable {
    /**
     * @dev Locks functions with whenNotLocked modifier
     */
    function lock() external onlyOwner {
        locked = true;
    }

    /**
     * @dev Throws if called after it was locked.
     */
    modifier whenNotLocked {
        require(!locked, "Lockable: locked");
        _;
    }
}