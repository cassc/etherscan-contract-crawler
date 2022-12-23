// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

abstract contract PausableControl {
    mapping(bytes32 => bool) private _pausedRoles;

    bytes32 public constant PAUSE_ALL_ROLE = 0x00;

    event Paused(bytes32 role);
    event Unpaused(bytes32 role);

    modifier whenNotPaused(bytes32 role) {
        require(
            !paused(role) && !paused(PAUSE_ALL_ROLE),
            "PausableControl: paused"
        );
        _;
    }

    modifier whenPaused(bytes32 role) {
        require(
            paused(role) || paused(PAUSE_ALL_ROLE),
            "PausableControl: not paused"
        );
        _;
    }

    function paused(bytes32 role) public view virtual returns (bool) {
        return _pausedRoles[role];
    }

    function _pause(bytes32 role) internal virtual whenNotPaused(role) {
        _pausedRoles[role] = true;
        emit Paused(role);
    }

    function _unpause(bytes32 role) internal virtual whenPaused(role) {
        _pausedRoles[role] = false;
        emit Unpaused(role);
    }
}