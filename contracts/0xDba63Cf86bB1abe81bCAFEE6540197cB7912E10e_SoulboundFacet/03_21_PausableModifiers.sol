// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PausableLib.sol";

abstract contract PausableModifiers {
    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        PausableLib.enforceUnpaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        PausableLib.enforcePaused();
        _;
    }
}