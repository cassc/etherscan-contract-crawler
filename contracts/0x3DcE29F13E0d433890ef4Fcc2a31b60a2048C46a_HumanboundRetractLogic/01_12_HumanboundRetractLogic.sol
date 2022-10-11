// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@violetprotocol/extendable/extensions/retract/RetractLogic.sol";
import { HumanboundPermissionState, HumanboundPermissionStorage } from "../../storage/HumanboundPermissionStorage.sol";

contract HumanboundRetractLogic is RetractLogic {
    modifier onlyOperatorOrSelf() virtual {
        HumanboundPermissionState storage state = HumanboundPermissionStorage._getState();
        require(
            _lastCaller() == state.operator || _lastCaller() == address(this),
            "HumanboundRetractLogic: unauthorised"
        );
        _;
    }

    // Overrides the previous implementation of modifier to remove owner checks
    modifier onlyOwnerOrSelf() override {
        _;
    }

    function retract(address extension) public override onlyOperatorOrSelf {
        super.retract(extension);
    }
}