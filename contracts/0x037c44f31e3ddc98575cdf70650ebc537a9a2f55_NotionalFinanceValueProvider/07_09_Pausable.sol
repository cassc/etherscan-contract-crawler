// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @notice Emitted when paused
error Pausable__whenNotPaused_paused();

/// @notice Emitted when not paused
error Pausable__whenPaused_notPaused();

import {Guarded} from "../guarded/Guarded.sol";

contract Pausable is Guarded {
    event Paused(address who);
    event Unpaused(address who);

    bool private _paused;

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        // If the contract is paused, throw an error
        if (_paused) {
            revert Pausable__whenNotPaused_paused();
        }
        _;
    }

    modifier whenPaused() {
        // If the contract is not paused, throw an error
        if (_paused == false) {
            revert Pausable__whenPaused_notPaused();
        }
        _;
    }

    function _pause() internal whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}