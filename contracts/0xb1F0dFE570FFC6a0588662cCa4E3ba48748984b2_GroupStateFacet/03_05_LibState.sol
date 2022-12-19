//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StorageState} from "../storage/StorageState.sol";
import {StateEnum} from "../structs/StateEnum.sol";

/// @author Amit Molek
/// @dev Contract/Group state
library LibState {
    string public constant INVALID_STATE_ERR = "State: Invalid state";

    event StateChanged(StateEnum from, StateEnum to);

    /// @dev Changes the state of the contract/group
    /// Can revert:
    ///     - "State: same state": When changing the state to the same one
    /// Emits `StateChanged` event
    /// @param state the new state
    function _changeState(StateEnum state) internal {
        StorageState.DiamondStorage storage ds = StorageState.diamondStorage();
        require(ds.state != state, "State: same state");

        emit StateChanged(ds.state, state);

        ds.state = state;
    }

    function _state() internal view returns (StateEnum) {
        StorageState.DiamondStorage storage ds = StorageState.diamondStorage();

        return ds.state;
    }

    /// @dev reverts if `state` is not the current contract state
    function _stateGuard(StateEnum state) internal view {
        require(_state() == state, INVALID_STATE_ERR);
    }
}