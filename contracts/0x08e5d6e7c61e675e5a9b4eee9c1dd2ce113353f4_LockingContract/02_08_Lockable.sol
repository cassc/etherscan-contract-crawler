// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.1;


abstract contract Lockable {
    bool private _locked;

    constructor() {
        _locked = false;
    }

    modifier whenNotLocked() {
        require(!_locked, "Lockable: already locked");
        _;
    }

    modifier whenLocked() {
        require(_locked, "Lockable: not locked yet");
        _;
    }

    function _lock() internal whenNotLocked {
        _locked = true;
    }

    function _isLocked() internal view returns (bool) {
        return _locked;
    }
}