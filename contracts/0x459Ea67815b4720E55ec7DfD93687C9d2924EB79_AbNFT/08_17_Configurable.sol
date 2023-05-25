// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

/**************************************

    Configurable

    ------------

    Base contract that should be inherited
    and setConfigured function should be overridden

 **************************************/

abstract contract Configurable {

    // enum
    enum State {
        UNCONFIGURED,
        CONFIGURED
    }

    // storage
    State public state; // default -> State.UNCONFIGURED;

    // events
    event Initialised(bytes);
    event Configured(bytes);

    // errors
    error InvalidState(State current, State expected);

    // modifier
    modifier onlyInState(State _state) {

        // check state
        if (state != _state) revert InvalidState(state, _state);
        _;

    }

    /**************************************

        Configuration

        -------------

        Should be overridden with
        proper access control

     **************************************/

    function setConfigured() public virtual
    onlyInState(State.UNCONFIGURED) {

        // set as configured
        state = State.CONFIGURED;

    }

}