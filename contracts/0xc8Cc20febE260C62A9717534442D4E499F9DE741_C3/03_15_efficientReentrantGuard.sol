// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title nonReentrant module to prevent recursive calling of functions
 * @dev See https://medium.com/coinmonks/protect-your-solidity-smart-contracts-from-reentrancy-attacks-9972c3af7c21
 */

abstract contract nonReentrant {
    bool private _reentryKey = false;
    modifier reentryLock() {
        require(!_reentryKey, "cannot reenter a locked function");
        _reentryKey = true;
        _;
        _reentryKey = false;
    }
}