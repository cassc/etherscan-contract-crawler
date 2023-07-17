// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

/// @notice This contract is an abstract configurable utility, that can be inherited in contracts needed 1-time setup.
abstract contract Configurable {
    // -----------------------------------------------------------------------
    //                              Enums
    // -----------------------------------------------------------------------

    /// @dev State definition (before or after setup).
    enum State {
        UNCONFIGURED,
        CONFIGURED
    }

    // -----------------------------------------------------------------------
    //                              State variables
    // -----------------------------------------------------------------------

    /// @dev Storage of current state of contract.
    State public state;

    // -----------------------------------------------------------------------
    //                              Events
    // -----------------------------------------------------------------------

    event Initialised(bytes args);
    event Configured(bytes args);

    // -----------------------------------------------------------------------
    //                              Errors
    // -----------------------------------------------------------------------

    error InvalidState(State state, State expected);

    // -----------------------------------------------------------------------
    //                              Modifiers
    // -----------------------------------------------------------------------

    /// @dev Ensures contract is in correct state.
    /// @param _state Current state of contract
    modifier onlyInState(State _state) {
        // check state
        if (state != _state) {
            revert InvalidState(state, _state);
        }

        // enter function
        _;
    }

    // -----------------------------------------------------------------------
    //                              External functions
    // -----------------------------------------------------------------------

    /// @dev Function to implement in inheriting contract, that will use byte encoded args for setup.
    /// @param _arguments Byte-encoded user-defined arguments
    function configure(bytes calldata _arguments) external virtual;
}