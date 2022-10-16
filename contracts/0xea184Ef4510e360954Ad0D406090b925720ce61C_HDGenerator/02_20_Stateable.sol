// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

error NotAllowedInCurrentState();

contract Stateable {
    enum State {
        Paused,
        Freedom
    }

    State public currentState;

    event StateSwitch(State newState);

    modifier inState(State _state) {
        if (currentState != _state) revert NotAllowedInCurrentState();
        _;
    }

    modifier notInState(State _state) {
        if (currentState == _state) revert NotAllowedInCurrentState();
        _;
    }

    function updateState(State _state) public virtual {
        currentState = _state;
        emit StateSwitch(_state);
    }
}