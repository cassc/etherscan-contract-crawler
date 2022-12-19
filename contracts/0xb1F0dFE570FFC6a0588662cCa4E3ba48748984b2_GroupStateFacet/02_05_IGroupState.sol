//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StateEnum} from "../structs/StateEnum.sol";

/// @title Group state interface
/// @author Amit Molek
interface IGroupState {
    /// @dev Emits on event change
    /// @param from the previous event
    /// @param to the new event
    event StateChanged(StateEnum from, StateEnum to);

    /// @return the current state of the contract/group
    function state() external view returns (StateEnum);
}