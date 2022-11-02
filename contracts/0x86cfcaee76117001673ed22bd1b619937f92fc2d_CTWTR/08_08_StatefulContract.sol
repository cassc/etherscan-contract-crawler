// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

error WrongStateException(
    StatefulContract.State expected,
    StatefulContract.State current
);
error UpgradeStateException(
    StatefulContract.State currentState,
    StatefulContract.State newState
);

abstract contract StatefulContract {
    event UpgradedState(State oldState, State newState);
    enum State {
        UNINITIALIZED,
        FAIRLAUNCH,
        OPEN
    }

    State private currentState = State.UNINITIALIZED;

    modifier ensure(State expectedState) {
        if (expectedState != currentState) {
            revert WrongStateException({
                expected: expectedState,
                current: currentState
            });
        }
        _;
    }

    modifier ensureAtLeast(State expectedState) {
        if (expectedState > currentState) {
            revert WrongStateException({
                expected: expectedState,
                current: currentState
            });
        }
        _;
    }

    function _getState() internal view returns (State) {
        return currentState;
    }

    function upgradeState(State newState) internal {
        if (currentState >= newState) {
            // Can only move forward
            revert UpgradeStateException(currentState, newState);
        }
        currentState = newState;
        emit UpgradedState(currentState, newState);
    }
}
