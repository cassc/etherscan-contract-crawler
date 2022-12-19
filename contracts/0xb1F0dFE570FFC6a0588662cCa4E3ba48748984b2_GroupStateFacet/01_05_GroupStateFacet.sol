//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LibState} from "../../libraries/LibState.sol";
import {IGroupState} from "../../interfaces/IGroupState.sol";
import {StateEnum} from "../../structs/StateEnum.sol";

/// @author Amit Molek
/// @dev Please see `IGroupState` for docs
contract GroupStateFacet is IGroupState {
    function state() external view override returns (StateEnum) {
        return LibState._state();
    }
}