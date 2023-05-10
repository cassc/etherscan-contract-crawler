// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/MutexErrors.sol";

abstract contract Mutex {
    uint256 internal constant _LOCKED = 1;
    uint256 internal constant _UNLOCKED = 2;
    uint256 internal _mutex;

    modifier withLock() {
        if (_mutex == _LOCKED) {
            revert MutexErrors.MutexLocked();
        }
        _mutex = _LOCKED;
        _;
        _mutex = _UNLOCKED;
    }
}