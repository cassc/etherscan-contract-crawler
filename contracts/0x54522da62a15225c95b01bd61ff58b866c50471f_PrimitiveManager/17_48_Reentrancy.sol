// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

/// @title   Reentrancy contract
/// @author  Primitive
/// @notice  Prevents reentrancy
contract Reentrancy {
    /// @notice  Thrown when a call to the contract is made during a locked state
    error LockedError();

    /// @dev Reentrancy guard initialized to state
    uint256 private _locked = 1;

    /// @notice  Locks the contract to prevent reentrancy
    modifier lock() {
        if (_locked != 1) revert LockedError();

        _locked = 2;
        _;
        _locked = 1;
    }
}