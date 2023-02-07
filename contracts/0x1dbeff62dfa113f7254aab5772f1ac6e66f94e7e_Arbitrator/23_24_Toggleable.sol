// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @notice Simple mixin to enable / disable a contract.
abstract contract Toggleable {
    error IsDisabled();

    /// @notice Indicates if the contract is enabled.
    bool public enabled;

    /// @dev Requires to be enabled before performing function.
    modifier isEnabled() {
        if (!enabled) revert IsDisabled();
        _;
    }

    /// @notice Enable / disable a contract.
    /// @param status New enabled status.
    function setEnabled(bool status) external virtual {
        enabled = status;
    }
}