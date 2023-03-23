// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Mutex {
    bool private _lock;

    modifier mutex() {
        require(!_lock, "mutex lock");
        _lock = true;
        _;
        _lock = false;
    }
}