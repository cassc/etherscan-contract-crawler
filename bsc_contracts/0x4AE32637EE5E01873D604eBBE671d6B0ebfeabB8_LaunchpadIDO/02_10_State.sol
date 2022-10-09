//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

 abstract contract State {

    /**
     * @dev the current state of the contrac.
     *
     * 0 is active
     * 1 is paused
     * 2 is cancelled
     * 3 is finalized
     */
    uint private _state;
    uint private _pauseStart;

    event ChangeState(uint status);

    constructor() {
        _state = 0;
    }

    modifier whenActive() {
        require(_state == 0, "State: not active");
        _;
    }

    modifier whenPaused() {
        require(_state == 1, "State: not paused");
        _;
    }

    modifier whenCancelled() {
        require(_state == 2, "State: not cancelled");
        _;
    }

    modifier whenFinalized() {
        require(_state == 3, "State: not finalized");
        _;
    }

    function state() public view returns (uint) {
        return _state;
    }

    /**
     * @dev Set the current state to active.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _activate() internal virtual whenPaused returns (uint duration) {
        _state = 0;
        duration = block.timestamp - _pauseStart; 
        emit ChangeState(0);
    }

    /**
     * @dev Set the current state to pause.
     *
     * Requirements:
     *
     * - The contract must be active.
     */
    function _pause() internal virtual whenActive {
        _state = 1;
        _pauseStart = block.timestamp;

        emit ChangeState(1);
    }

    /**
     * @dev Set the current state to pause.
     *
     * Requirements:
     *
     * - The contract must be active or paused.
     */
    function _cancel() internal virtual {
        require(_state == 0 || _state == 1, "State: not active or paused");
        _state = 2;

        emit ChangeState(2);
    }

    /**
     * @dev Set the current state to pause.
     *
     * Requirements:
     *
     * - The contract must be active or paused.
     */
    function _finalized() internal virtual {
        require(_state == 0 || _state == 1, "State: not active or paused");
        _state = 3;

        emit ChangeState(3);
    }
}